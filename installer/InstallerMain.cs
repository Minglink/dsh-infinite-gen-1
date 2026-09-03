// DSH 无限三代 (dsh-infinite-gen-3) 一键安装器 —— 引擎层
// Windows / .NET Framework 4.x，仅系统自带程序集，无外部运行库。
// 注意：本文件须保持 C# 5 兼容（不使用表达式体成员、行内 out、?. 等 C#6+ 语法），
//       以便用系统自带的 Csc 直接编译，任何 Windows 均可运行。
// 与 InstallerForm.cs（窗体）、Build.ps1（构建脚本）、BundleData.g.cs（嵌入载荷）配套。

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Web.Script.Serialization;

namespace DshInfinite
{
    internal static class Program
    {
        [System.STAThread]
        internal static void Main(string[] args)
        {
            bool selfTest = args != null && Array.IndexOf(args, "--selfcheck") >= 0;
            if (selfTest)
            {
                string outText;
                int code = Engine.SelfCheck(out outText);
                string dest = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
                    "无限三代-自检结果.log");
                try { File.WriteAllText(dest, outText, Encoding.UTF8); } catch { }
                Environment.ExitCode = code;
                return;   // process ends (结果写入 %USERPROFILE%\无限三代-自检结果.log)
            }

            System.Windows.Forms.Application.EnableVisualStyles();
            System.Windows.Forms.Application.SetCompatibleTextRenderingDefault(false);
            System.Windows.Forms.Application.Run(new InstallerForm(args));
        }
    }

    internal static class Fs
    {
        public static string ReadUtf8(string path)
        {
            return Encoding.UTF8.GetString(File.ReadAllBytes(path));
        }

        public static void WriteUtf8(string path, string text)
        {
            text = text.Replace("\r\n", "\n").Replace("\n", "\r\n");
            File.WriteAllBytes(path, new UTF8Encoding(false).GetBytes(text));
        }

        public static void BackupIfExists(string path)
        {
            if (path != null && File.Exists(path))
            {
                try { File.Copy(path, path + ".bak", true); }
                catch { }
            }
        }
    }

    /// <summary>一个可安装的 DSH 运行时实例。</summary>
    public sealed class DshTarget
    {
        public bool IsDesktop;
        public string Kind;
        public string HomeRoot;
        public string ProfilesRoot;
        public string PkgJson;
        public string MainModules;
        public bool IsLive;
        public bool RegistryPresent;
        public bool FolderPresent;

        public override string ToString()
        {
            return Kind + "  \u00b7  " + HomeRoot;
        }
    }

    public static class Finder
    {
        public const string Id = "dsh-infinite-gen-3";

        public static List<DshTarget> Discover(bool markLive)
        {
            string cur = markLive ? HomeOfCurrent() : null;
            var list = new List<DshTarget>();
            var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            var desktopHome = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "@deepseek-ai", "dsh-desktop", "dsh-home");
            var cliHome = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".dsh");

            // 桌面版与 CLI 版都可能是“当前运行”。把当前实例排到前面。
            var desk = BuildTarget(desktopHome, true, "桌面客户端", cur);
            var clic = BuildTarget(cliHome, false, "CLI / Web 版", cur);
            var pick = new List<DshTarget>();
            if (cur != null)
            {
                if (desk != null && PathEquals(desk.HomeRoot, cur)) pick.Add(desk);
                if (clic != null && PathEquals(clic.HomeRoot, cur)) pick.Add(clic);
            }
            if (desk != null && !pick.Contains(desk)) pick.Add(desk);
            if (clic != null && !pick.Contains(clic)) pick.Add(clic);
            return pick;
        }

        private static DshTarget BuildTarget(string home, bool isDesktop, string kindBase, string cur)
        {
            if (!Directory.Exists(home)) return null;
            string profiles = Path.Combine(home, "profiles");
            if (!Directory.Exists(profiles)) return null;

            bool isLive = cur != null && PathEquals(home, cur);

            var t = new DshTarget
            {
                IsDesktop = isDesktop,
                HomeRoot = home,
                ProfilesRoot = profiles,
                IsLive = isLive,
            };
            t.Kind = kindBase + (isLive ? "（当前运行 → 装后需重启）" : "");
            t.PkgJson = Path.Combine(profiles, "web", "package.json");
            t.MainModules = Path.Combine(profiles, "node_modules", Id);
            t.RegistryPresent = File.Exists(t.PkgJson) && Engine.IsRegistered(t.PkgJson, Id);
            t.FolderPresent = Directory.Exists(t.MainModules);
            return t;
        }

        public static string HomeOfCurrent()
        {
            string h = Environment.GetEnvironmentVariable("DSH_HOME");
            if (!string.IsNullOrWhiteSpace(h) && Directory.Exists(h)) return h;
            var desk = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "@deepseek-ai", "dsh-desktop", "dsh-home");
            if (Directory.Exists(Path.Combine(desk, "profiles"))) return desk;
            var cli = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".dsh");
            if (Directory.Exists(Path.Combine(cli, "profiles"))) return cli;
            return null;
        }

        internal static bool PathEquals(string a, string b)
        {
            return string.Equals(a.TrimEnd('\\', '/'), b.TrimEnd('\\', '/'), StringComparison.OrdinalIgnoreCase);
        }
    }

    public sealed class Report
    {
        public bool OK;
        public readonly List<string> Lines = new List<string>();

        public void Add(string s) { Lines.Add(s); }

        public string Text
        {
            get { return string.Join(Environment.NewLine, Lines); }
        }
    }

    /// <summary>安装 / 修复 / 卸载引擎（幂等、自动备份、JSON 写后校验回滚）。</summary>
    public static class Engine
    {
        public const string PlugName = "dsh-infinite-gen-3";

        // ================= 安装 =================
        public static Report Install(DshTarget t)
        {
            var r = new Report();
            try
            {
                byte[] zip = BundleData.GetPayload();
                if (zip == null || zip.Length == 0)
                {
                    r.OK = false;
                    r.Add("错误：未载入插件数据。请用构建脚本重新生成安装器。");
                    return r;
                }

                r.Add("目标：" + t.HomeRoot);
                // 1) 写插件主模块
                string deployNote;
                DeployModule(t.MainModules, zip, out deployNote);
                r.Add("[1/3] 插件文件");
                SplitLog(r, deployNote);
                r.Add("       文件数：" + CountFiles(t.MainModules));

                // 2) 登记 bundles
                r.Add("[2/3] bundle 登记");
                if (!File.Exists(t.PkgJson))
                {
                    r.Add("       未找到 <profiles>/web/package.json → 跳过登记（若为桌面版请检查路径）。");
                }
                else if (IsRegistered(t.PkgJson, PlugName))
                {
                    r.Add("       已在 dsh.profile.bundles 登记，无需重复。");
                }
                else
                {
                    string msg;
                    Register(t, out msg);
                    r.Add("       " + Flatten(msg));
                }

                r.OK = true;
                r.Add("[3/3] 完成");
                r.Add(t.IsLive
                    ? "       插件已就绪。当前任务即运行在此实例中，请重启 DSH / 重新加载会话以生效。"
                    : "       插件已就绪。该实例未运行，将在下次启动时自动加载。");
            }
            catch (Exception ex)
            {
                r.OK = false;
                r.Add("异常：" + ex.Message);
                if (ex.InnerException != null) r.Add("详情：" + ex.InnerException.Message);
            }
            return r;
        }

        // ================= 卸载 =================
        public static Report Uninstall(DshTarget t)
        {
            var r = new Report();
            try
            {
                r.Add("目标：" + t.HomeRoot);
                if (Directory.Exists(t.MainModules))
                {
                    r.Add("删除主模块：" + SafeDeleteDir(t.MainModules));
                }
                else
                {
                    r.Add("主模块目录不存在，跳过。");
                }
                r.Add("清理 bundles 登记：");
                if (File.Exists(t.PkgJson))
                {
                    if (IsRegistered(t.PkgJson, PlugName))
                    {
                        string msg;
                        Unregister(t, out msg);
                        r.Add("       " + msg);
                    }
                    else r.Add("       bundles 中无该登记，跳过。");
                }
                else r.Add("       无配置文件，跳过。");
                r.OK = true;
                r.Add("卸载完成。");
            }
            catch (Exception ex)
            {
                r.OK = false; r.Add("异常：" + ex.Message);
            }
            return r;
        }

        // ================= 检查 =================
        public static Report Inspect(DshTarget t)
        {
            var r = new Report();
            r.Add("检查目标：" + t.HomeRoot);
            r.Add("  主模块目录：  " + (Directory.Exists(t.MainModules) ? t.MainModules : "不存在"));
            if (Directory.Exists(t.MainModules))
                r.Add("  文件数：      " + CountFiles(t.MainModules));
            r.Add("  注册状态：    " + (IsRegistered(t.PkgJson, PlugName) ? "已在 dsh.profile.bundles 登记" : "未登记"));
            r.Add("  配置文件：    " + (File.Exists(t.PkgJson) ? t.PkgJson : "（缺失）"));
            r.OK = true;
            return r;
        }

        // ================= 部署 ZIP =================
        private static void DeployModule(string dir, byte[] data, out string note)
        {
            note = "";
            string parentDir = Path.GetDirectoryName(dir);
            Directory.CreateDirectory(parentDir);
            string stamp = DateTime.Now.ToString("yyyyMMddHHmmss");
            string backup = Path.Combine(parentDir, PlugName + ".bak-" + stamp);
            bool madeBackup = false;
            if (Directory.Exists(dir))
            {
                try { Directory.Move(dir, backup); madeBackup = true; }
                catch { ClearContents(dir); }
            }
            Directory.CreateDirectory(dir);

            using (var ms = new MemoryStream(data))
            using (var zip = new System.IO.Compression.ZipArchive(ms, System.IO.Compression.ZipArchiveMode.Read))
            {
                foreach (var e in zip.Entries)
                {
                    if (string.IsNullOrEmpty(e.Name)) continue;
                    string rel = StripRoot(e.FullName);
                    if (rel.Length == 0) continue;
                    string dest = Path.Combine(dir, rel);
                    Directory.CreateDirectory(Path.GetDirectoryName(dest));
                    using (var src = e.Open())
                    using (var dst = File.Create(dest))
                        src.CopyTo(dst);
                }
            }
            List<string> parts = new List<string>();
            parts.Add("       已写入目录：profiles\\node_modules\\" + PlugName);
            if (madeBackup) parts.Add("       旧版本已备份为 " + backup);
            note = string.Join("\n", parts.ToArray());
        }

        private static string StripRoot(string entry)
        {
            const string guard = "pluginroot/";
            if (entry.StartsWith(guard, StringComparison.Ordinal))
                return entry.Substring(guard.Length);
            return entry;
        }

        // ================= 登记操作 =================
        public static bool IsRegistered(string pkgJson, string id)
        {
            if (!File.Exists(pkgJson)) return false;
            string txt = Fs.ReadUtf8(pkgJson);
            return ContainsTok(txt, id);
        }

        private static bool ContainsTok(string txt, string id)
        {
            return txt.Contains("\"" + id + "\"") || txt.Contains("'" + id + "'");
        }

        public static void Register(DshTarget t, out string msg)
        {
            msg = "";
            string path = t.PkgJson;
            Fs.BackupIfExists(path);
            string before = Fs.ReadUtf8(path);
            string after = AddToArray(before, PlugName);
            if (after == before)
            {
                msg = "未能识别 dsh.profile.bundles 数组结构，未改动（已保留备份）。";
                return;
            }
            Fs.WriteUtf8(path, after);
            if (!IsValidJson(path))
            {
                Restore(path);
                msg = "写后 JSON 校验未通过，已自动回滚。请手动检查 package.json。";
                return;
            }
            msg = "已在 dsh.profile.bundles 登记「" + PlugName + "」" +
                  (File.Exists(path + ".bak") ? "（原文件已备份）" : "") + "。";
        }

        public static void Unregister(DshTarget t, out string msg)
        {
            msg = "";
            string path = t.PkgJson;
            Fs.BackupIfExists(path);
            string before = Fs.ReadUtf8(path);
            string after = RemoveFromArray(before, PlugName);
            if (after == before) { msg = "bundles 中无该登记，跳过。"; return; }
            Fs.WriteUtf8(path, after);
            if (!IsValidJson(path)) { Restore(path); msg = "写后 JSON 校验失败，已回滚。"; return; }
            msg = "已从 bundles 移除登记。";
        }

        private static void Restore(string path)
        {
            try { if (File.Exists(path + ".bak")) File.Copy(path + ".bak", path, true); }
            catch { }
        }

        private static bool IsValidJson(string path)
        {
            try
            {
                var ser = new JavaScriptSerializer();
                ser.MaxJsonLength = int.MaxValue;
                ser.DeserializeObject(Fs.ReadUtf8(path));
                return true;
            }
            catch { return false; }
        }

        // -------------------- 精确文本编辑 bundles 数组 --------------------
        // 采用轻量「查括号」的方式，避免破坏 注释 / 换行 / 缩进，并对写入结果做 JSON 校验。
        // 返回：新字符串；若未能定位则返回原字符串。

        public static string AddToArray(string json, string id)
        {
            if (ContainsTok(json, id)) return json;
            int rb = ProfileBundlesCloseBracket(json);
            if (rb < 0) return json;

            string headExclClose = json.Substring(0, rb);   // 含 ']' 前的空白
            string tail = json.Substring(rb);                // 从 ']' 起
            string trimmed = headExclClose.TrimEnd();
            bool empty = trimmed.EndsWith("[");
            string ws = headExclClose.Substring(trimmed.Length);
            string core;
            if (empty)
                core = trimmed + "\"" + id + "\"";
            else
                core = trimmed + ", \"" + id + "\"";
            return core + ws + tail;
        }

        public static string RemoveFromArray(string json, string id)
        {
            string[] toks = { "\"" + id + "\"", "'" + id + "'" };
            string s = json;
            for (int ti = 0; ti < toks.Length; ti++)
            {
                string tok = toks[ti];
                for (; ; )
                {
                    int i = s.IndexOf(tok, StringComparison.Ordinal);
                    if (i < 0) break;
                    int start = i, end = i + tok.Length;
                    // 优先吞掉“前面的逗号+空白”
                    int pre = i - 1;
                    while (pre >= 0 && char.IsWhiteSpace(s[pre])) pre--;
                    bool preTaken = false;
                    if (pre >= 0 && s[pre] == ',')
                    {
                        start = pre;
                        preTaken = true;
                    }
                    if (!preTaken)
                    {
                        int post = end;
                        while (post < s.Length && char.IsWhiteSpace(s[post])) post++;
                        if (post < s.Length && s[post] == ',') end = post + 1;
                    }
                    s = s.Substring(0, start) + s.Substring(end);
                }
            }
            return s;
        }

        private static int ProfileBundlesCloseBracket(string json)
        {
            int prof = json.IndexOf("\"profile\"", StringComparison.Ordinal);
            if (prof < 0) prof = 0;
            int bi = json.IndexOf("bundles", prof, StringComparison.Ordinal);
            if (bi < 0) return -1;
            int open = json.IndexOf('[', bi);
            if (open < 0) return -1;
            int depth = 0;
            for (int i = open; i < json.Length; i++)
            {
                char c = json[i];
                if (c == '[') depth++;
                else if (c == ']')
                {
                    depth--;
                    if (depth == 0) return i;
                }
            }
            return -1;
        }

        // ================= 通用 =================

        internal static bool IsRunning(string name)
        {
            try { return System.Diagnostics.Process.GetProcessesByName(name).Length > 0; }
            catch { return false; }
        }

        internal static void StartProcess(string file)
        {
            try
            {
                System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo(file)
                {
                    UseShellExecute = true,
                    CreateNoWindow = false
                });
            }
            catch { }
        }

        private static int CountFiles(string dir)
        {
            try { return Directory.GetFiles(dir, "*", SearchOption.AllDirectories).Length; }
            catch { return 0; }
        }

        private static void ClearContents(string dir)
        {
            foreach (var f in Directory.GetFiles(dir)) { try { File.Delete(f); } catch { } }
            foreach (var d in Directory.GetDirectories(dir)) { try { Directory.Delete(d, true); } catch { } }
        }

        private static string SafeDeleteDir(string dir)
        {
            try { Directory.Delete(dir, true); return "已完成删除。"; }
            catch (Exception ex) { return "删除失败：" + ex.Message; }
        }

        // ================= 日志辅助 =================

        internal static void SplitLog(Report r, string multiLine)
        {
            if (multiLine == null) return;
            string[] lines = multiLine.Replace("\r", "").Split('\n');
            for (int i = 0; i < lines.Length; i++)
            {
                string s = lines[i];
                if (!string.IsNullOrWhiteSpace(s)) r.Add("       " + s.Trim());
            }
        }

        internal static string Flatten(string s)
        {
            if (s == null) return "";
            return s.Replace("\r", "").Replace("\n", " ");
        }

        internal static string LocalTime()
        {
            return DateTime.Now.ToString("HH:mm:ss");
        }

        // ================= 自检（供 --selfcheck 调用，仅操作临时目录） =================
        internal static int SelfCheck(out string text)
        {
            var sb = new StringBuilder();
            sb.AppendLine("无限三代安装器自检 (self-check)");
            sb.AppendLine("时间: " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss"));
            string tmp = Path.Combine(Path.GetTempPath(), "dshig3-selfcheck-" + Guid.NewGuid().ToString("N"));
            try
            {
                // 搭建假 profile
                string profiles = Path.Combine(tmp, "profiles");
                string web = Path.Combine(profiles, "web");
                string mainNm = Path.Combine(profiles, "node_modules", PlugName);
                Directory.CreateDirectory(Path.Combine(web, "node_modules"));
                Directory.CreateDirectory(mainNm);
                string pkg = Path.Combine(web, "package.json");
                string sample = "{\r\n  \"name\": \"web\",\r\n  \"private\": true,\r\n" +
                                "  \"dsh\": {\r\n    \"profile\": {\r\n      \"bundles\": [\r\n        \"@deepseek-ai/dsh-base\",\r\n        \"@deepseek-ai/dsh-web-app\"\r\n      ],\r\n      \"patchReload\": \"live\"\r\n    }\r\n  }\r\n}\r\n";
                Fs.WriteUtf8(pkg, sample);

                var t = new DshTarget();
                t.HomeRoot = tmp;
                t.ProfilesRoot = profiles;
                t.PkgJson = pkg;
                t.MainModules = mainNm;
                t.IsLive = false;

                // 1) 登记
                sb.AppendLine("[1] 校验 bundes 登记逻辑（Add/Remove 到 package.json）");
                string before = Fs.ReadUtf8(pkg);
                string add1 = AddToArray(before, PlugName);
                Fs.WriteUtf8(pkg, add1);
                bool added = IsRegistered(pkg, PlugName);
                sb.AppendLine("    登记后 IsRegistered=" + added);
                if (!added) { sb.AppendLine("FAIL: 登记后未检测到"); text = sb.ToString(); return 2; }
                if (!IsValidJsonText(add1)) { sb.AppendLine("FAIL: 登记后 JSON 无效"); text = sb.ToString(); return 2; }

                string back1 = RemoveFromArray(add1, PlugName);
                bool removed = !ContainsTok(back1, PlugName);
                sb.AppendLine("    移除后 Contains=" + ContainsTok(back1, PlugName));
                if (!removed) { sb.AppendLine("FAIL: 移除后仍包含"); text = sb.ToString(); return 2; }
                if (!IsValidJsonText(back1)) { sb.AppendLine("FAIL: 移除后 JSON 无效"); text = sb.ToString(); return 2; }
                sb.AppendLine("OK  登记/移除文本编辑通过");
                Fs.WriteUtf8(pkg, back1);

                // 2) 部署 ZIP
                sb.AppendLine("[2] 部署嵌入 zip 到临时 node_modules");
                byte[] zip = BundleData.GetPayload();
                if (zip == null || zip.Length == 0) { sb.AppendLine("FAIL: 嵌入载荷为空"); text = sb.ToString(); return 3; }
                sb.AppendLine("    载荷大小=" + zip.Length + " 字节");
                string depNote;
                DeployModule(mainNm, zip, out depNote);
                int cnt = CountFiles(mainNm);
                sb.AppendLine("    解压文件数=" + cnt);
                sb.AppendLine("    " + Flatten(depNote));
                bool hasIndex = File.Exists(Path.Combine(mainNm, "index.js"));
                bool hasPrompt = File.Exists(Path.Combine(mainNm, "prompts", "infinite-gen-3.md"));
                sb.AppendLine("    index.js 存在=" + hasIndex + " ; prompts/infinite-gen-3.md 存在=" + hasPrompt);
                if (cnt < 5 || !hasIndex || !hasPrompt) { text = sb.ToString(); return 3; }

                text = sb.ToString() + Environment.NewLine + "自检结果: 全部通过 (PASS)";
                return 0;
            }
            catch (Exception ex)
            {
                sb.AppendLine("自检异常: " + ex.Message);
                if (ex.InnerException != null) sb.AppendLine("详情: " + ex.InnerException.Message);
                text = sb.ToString();
                return 1;
            }
            finally
            {
                try { if (Directory.Exists(tmp)) Directory.Delete(tmp, true); } catch { }
            }
        }

        private static bool IsValidJsonText(string text2)
        {
            try
            {
                var ser = new JavaScriptSerializer();
                ser.MaxJsonLength = int.MaxValue;
                ser.DeserializeObject(text2);
                return true;
            }
            catch { return false; }
        }
    }
}
