// DSH 无限三代 (dsh-infinite-gen-3) 一键安装器 —— WinForms 图形界面
// Windows / .NET Framework 4.x，无外部运行库。
// 注意：保持 C# 5 兼容（不用表达式体/行内 out/?. 等 C#6 语法），配合系统自带 Csc 编译。
// 引擎见 InstallerMain.cs；构建见 Build.ps1。

using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Text;
using System.Windows.Forms;

namespace DshInfinite
{
    public sealed class InstallerForm : Form
    {
        private ComboBox _ddl;
        private TextBox _log;
        private Label _status;
        private Label _meta;
        private List<DshTarget> _targets;
        private System.Windows.Forms.Timer _timer;

        public InstallerForm(string[] args)
        {
            this.Text = "无限三代 (dsh-infinite-gen-3) 一键安装器";
            this.Font = new Font("Microsoft YaHei UI", 9F);
            this.FormBorderStyle = FormBorderStyle.FixedDialog;
            this.MaximizeBox = false;
            this.MinimizeBox = true;
            this.StartPosition = FormStartPosition.CenterScreen;
            this.ClientSize = new Size(660, 576);
            this.BackColor = Color.White;

            BuildBanner();
            BuildMain();
            this.Load += delegate
            {
                RefreshTargets();
                Log("欢迎使用「无限三代」一键安装器。");
                Log("・自动检测到下方 DSH 运行时实例。若为当前运行的实例，装后需重启 DSH 以加载。");
                Log("・点「一键安装/修复」即完成：写插件文件 ＋ 登记 bundles，全程自动备份与校验回滚。");
            };

            _timer = new System.Windows.Forms.Timer();
            _timer.Interval = 1500;
            _timer.Tick += delegate { try { RefreshStatusOnly(); } catch { } };
            _timer.Start();
        }

        private void BuildBanner()
        {
            var banner = new Panel();
            banner.Dock = DockStyle.Top;
            banner.Height = 76;
            banner.BackColor = Color.FromArgb(14, 138, 120);
            this.Controls.Add(banner);

            Label t = new Label();
            t.Text = "\u2694  无限三代  ·  dsh-infinite-gen-3 一键安装器";
            t.ForeColor = Color.White;
            t.BackColor = Color.Transparent;
            t.Font = new Font("Microsoft YaHei UI", 16F, FontStyle.Bold);
            t.AutoSize = false;
            t.Location = new Point(16, 12);
            t.Size = new Size(620, 32);
            banner.Controls.Add(t);

            Label s = new Label();
            s.Text = "破甲输出契约 · 无条件服从提示词插件  v0.5.0    ——   图形化写入 DSH profiles";
            s.ForeColor = Color.FromArgb(214, 255, 247);
            s.BackColor = Color.Transparent;
            s.AutoSize = true;
            s.Location = new Point(18, 50);
            banner.Controls.Add(s);
        }

        private void BuildMain()
        {
            Label lb = new Label();
            lb.Text = "请选择要安装到的 DSH 实例（自动检测「桌面客户端」与「CLI / Web 版」）：";
            lb.Location = new Point(18, 94);
            lb.AutoSize = true;
            this.Controls.Add(lb);

            _ddl = new ComboBox();
            _ddl.Location = new Point(18, 120);
            _ddl.Size = new Size(476, 24);
            _ddl.DropDownStyle = ComboBoxStyle.DropDownList;
            _ddl.SelectedIndexChanged += delegate { RefreshStatusOnly(); };
            this.Controls.Add(_ddl);

            Button btnRefresh = new Button();
            btnRefresh.Text = "重新检测";
            btnRefresh.Location = new Point(506, 118);
            btnRefresh.Size = new Size(126, 28);
            btnRefresh.Click += delegate { RefreshTargets(); };
            this.Controls.Add(btnRefresh);

            _status = new Label();
            _status.ForeColor = Color.DimGray;
            _status.Location = new Point(18, 154);
            _status.AutoSize = true;
            _status.MaximumSize = new Size(620, 0);
            this.Controls.Add(_status);

            _meta = new Label();
            _meta.ForeColor = Color.FromArgb(11, 96, 180);
            _meta.Location = new Point(18, 180);
            _meta.AutoSize = true;
            _meta.MaximumSize = new Size(620, 0);
            this.Controls.Add(_meta);

            Button bInst = MakeButton("一键安装 / 修复", 18, 210, 152);
            bInst.Click += delegate { RunInstall(false); };

            Button bForce = MakeButton("强制覆盖重装", 186, 210, 132);
            bForce.Click += delegate { RunInstall(true); };

            Button bUn = MakeButton("卸载", 330, 210, 78);
            bUn.Click += delegate { DoUninstall(); };

            Button bInsp = MakeButton("检查状态", 420, 210, 100);
            bInsp.Click += delegate { DoInspect(); };

            Button bOpen = MakeButton("打开 profiles", 532, 210, 100);
            bOpen.Click += delegate { DoOpen(); };

            Label logLabel = new Label();
            logLabel.Text = "操作日志：";
            logLabel.Location = new Point(18, 248);
            logLabel.AutoSize = true;
            this.Controls.Add(logLabel);

            _log = new TextBox();
            _log.Multiline = true;
            _log.ReadOnly = true;
            _log.ScrollBars = ScrollBars.Vertical;
            _log.Location = new Point(18, 272);
            _log.Size = new Size(614, 232);
            _log.BackColor = Color.FromArgb(247, 247, 247);
            _log.BorderStyle = BorderStyle.FixedSingle;
            _log.Font = new Font("Consolas", 9F);
            this.Controls.Add(_log);

            Label tip = new Label();
            tip.Text = "说明：插件写入会覆盖该实例的 profiles\\node_modules\\dsh-infinite-gen-3（旧版本自动备份）；\r\n" +
                       "登记写入 package.json 前自动生成 .bak，写后做 JSON 校验，失败即回滚，安全可靠。";
            tip.ForeColor = Color.DimGray;
            tip.Location = new Point(18, 514);
            tip.AutoSize = true;
            this.Controls.Add(tip);
        }

        private Button MakeButton(string text, int x, int y, int w)
        {
            Button b = new Button();
            b.Text = text;
            b.Location = new Point(x, y);
            b.Width = w;
            this.Controls.Add(b);
            return b;
        }

        private DshTarget Selected()
        {
            if (_targets == null || _targets.Count == 0) return null;
            int idx = _ddl.SelectedIndex;
            if (idx < 0 || idx >= _targets.Count) idx = 0;
            return _targets[idx];
        }

        private void RefreshTargets()
        {
            _targets = Finder.Discover(true);
            _ddl.Items.Clear();
            for (int i = 0; i < _targets.Count; i++)
            {
                DshTarget tk = _targets[i];
                string reg = tk.RegistryPresent ? "●已登记" : "○未登记";
                string fold = tk.FolderPresent ? "已存在" : "未安装";
                _ddl.Items.Add(tk.Kind + "    [目录:" + fold + " / bundles:" + reg + "]");
            }
            if (_targets.Count == 0)
            {
                Log("<未检测到已安装的 DSH 实例>");
                Log("请先安装 DeepSeek Harness（桌面版）或配置 CLI 版 profiles 后再运行本工具。");
                _ddl.Enabled = false;
            }
            else
            {
                _ddl.Enabled = true;
                _ddl.SelectedIndex = 0;
            }
            RefreshStatusOnly();
        }

        private void RefreshStatusOnly()
        {
            DshTarget t = Selected();
            if (t == null)
            {
                _status.Text = "";
                _meta.Text = "";
                return;
            }
            _status.Text = "目标 profiles：  " + t.HomeRoot;
            if (t.IsLive)
            {
                _meta.Text = "\u2605 当前任务正运行于该实例 —— 安装完成后请重启 DSH / 重建会话以加载插件。";
            }
            else
            {
                _meta.Text = "该实例当前未运行；安装后将于下次启动时自动加载。";
            }
        }

        // ================= 动作 =================

        private void RunInstall(bool force)
        {
            DshTarget t = Selected();
            if (t == null) { Log("请先选择一个安装目标。"); return; }

            Log("──────── 开始操作：" + (force ? "强制覆盖" : "安装 / 修复") + " ────────");
            Log("目标：" + t.HomeRoot);

            bool alreadyInstalled = (Directory.Exists(t.MainModules) && t.FolderPresent) || t.RegistryPresent;
            if (alreadyInstalled && !force)
            {
                DialogResult dr = MessageBox.Show(this,
                    "目标实例已安装「无限三代」。\n\n" +
                    "・若需修复 / 覆盖到嵌入式版本的包，点「是」。\n" +
                    "・仅复制缺失/更新文件，仍然安全（旧文件自动备份）。\n\n继续吗？",
                    "确认", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
                if (dr != DialogResult.Yes) { Log("已取消。"); return; }
            }

            Report rep = Engine.Install(t);
            foreach (string ln in rep.Lines) Log(ln);
            RefreshTargets();

            if (rep.OK)
            {
                MessageBox.Show(this,
                    t.IsLive
                        ? "安装完成。\n\n当前 DSH 实例正在运行，请重启桌面客户端 / 重建会话以加载插件。"
                        : "安装完成。该实例下次启动时将自动加载插件。",
                    "已完成", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            else
            {
                MessageBox.Show(this, "安装未完全成功，请查看上方日志。", "提示", MessageBoxButtons.OK,
                    MessageBoxIcon.Warning);
            }
        }

        private void DoUninstall()
        {
            DshTarget t = Selected();
            if (t == null) { Log("请先选择目标。"); return; }
            DialogResult dr = MessageBox.Show(this,
                "将卸载「无限三代」：\n\n  1) 删除插件目录\n  2) 移除 bundles 登记\n\n" +
                "（操作前都会备份，安全）。确认继续？",
                "确认卸载", MessageBoxButtons.OKCancel, MessageBoxIcon.Warning);
            if (dr != DialogResult.OK) { Log("已取消卸载。"); return; }

            Log("──────── 开始卸载： " + t.HomeRoot + " ────────");
            Report rep = Engine.Uninstall(t);
            foreach (string ln in rep.Lines) Log(ln);
            RefreshTargets();
            MessageBox.Show(this, rep.OK ? "卸载完成。" : "卸载出现异常，请查看日志。", "结果",
                MessageBoxButtons.OK, rep.OK ? MessageBoxIcon.Information : MessageBoxIcon.Warning);
        }

        private void DoInspect()
        {
            DshTarget t = Selected();
            if (t == null) { Log("请先选择目标。"); return; }
            Log("──────── 状态检查： " + t.HomeRoot + " ────────");
            Report rep = Engine.Inspect(t);
            foreach (string ln in rep.Lines) Log(ln);
        }

        private void DoOpen()
        {
            DshTarget t = Selected();
            if (t == null) { Log("请先选择目标。"); return; }
            try
            {
                string target = Path.Combine(t.ProfilesRoot, "web");
                if (!Directory.Exists(target)) target = t.HomeRoot;
                System.Diagnostics.Process.Start("explorer.exe", target);
            }
            catch (Exception ex) { Log("打开目录失败：" + ex.Message); }
        }

        // ================= 日志 =================

        private void Log(string msg)
        {
            if (_log == null || _log.IsDisposed) return;
            _log.AppendText(Engine.LocalTime() + "  " + msg + "\r\n");
            _log.SelectionStart = _log.TextLength;
            _log.ScrollToCaret();
        }

        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            if (_timer != null) { _timer.Stop(); _timer.Dispose(); }
            base.OnFormClosing(e);
        }
    }
}
