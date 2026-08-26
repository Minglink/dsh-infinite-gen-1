/* 无限二代 (dsh-infinite-gen-2) client half — realtime "破甲已开启" badge v2.
 * The badge is a toggle button. Clicking it runs `/armor off|on`
 * through the host commands Remote (same channel as the plan chip); the host
 * "armor" session projection then carries `enabled` back:
 *   enabled  -> green ● 破甲已开启 (pulse on user message, verdict flash after reply)
 *   disabled -> gray ● 破甲已关闭
 *   pending  -> 切换中… (single in-flight toggle at a time)
 */
window.__ModuleLoader__.load({
  id: "dsh-infinite-gen-2",
  factory: (require) => {
    var module = { exports: {} };
    var exports = module.exports;
    Object.defineProperty(exports, Symbol.toStringTag, { value: "Module" });

    var react = require("react");

    var inject = ["slots", "remote", "remote.commands"];

    var ANIM_CSS = "@keyframes dshArmorPulse{0%,100%{box-shadow:0 0 2px rgba(34,197,94,.5);opacity:1}50%{box-shadow:0 0 12px rgba(34,197,94,1);opacity:.55}}@keyframes dshArmorFlash{0%{transform:scale(1)}30%{transform:scale(1.12)}100%{transform:scale(1)}}";

    var WRAP_STYLE = {
      display: "flex",
      justifyContent: "center",
      width: "100%"
    };
    var BADGE_STYLE = {
      display: "inline-flex",
      alignItems: "center",
      gap: "5px",
      width: "fit-content",
      padding: "3px 10px",
      borderRadius: "6px",
      border: "1px solid rgba(34, 197, 94, 0.4)",
      background: "rgba(34, 197, 94, 0.1)",
      color: "inherit",
      fontSize: "11px",
      lineHeight: "16px",
      fontFamily: "inherit",
      userSelect: "none",
      whiteSpace: "nowrap",
      cursor: "pointer"
    };
    var BADGE_OFF_STYLE = {
      display: "inline-flex",
      alignItems: "center",
      gap: "5px",
      width: "fit-content",
      padding: "3px 10px",
      borderRadius: "6px",
      border: "1px solid rgba(148, 163, 184, 0.5)",
      background: "rgba(148, 163, 184, 0.12)",
      color: "inherit",
      fontSize: "11px",
      lineHeight: "16px",
      fontFamily: "inherit",
      userSelect: "none",
      whiteSpace: "nowrap",
      cursor: "pointer"
    };
    var DOT_STYLE = {
      width: "6px",
      height: "6px",
      borderRadius: "50%",
      background: "#22c55e",
      flex: "none"
    };
    var DOT_OFF_STYLE = {
      width: "6px",
      height: "6px",
      borderRadius: "50%",
      background: "#94a3b8",
      flex: "none"
    };
    var FLASH_MS = 2500;

    function ArmorDock(props) {
      var useProjection = props.useProjection;
      var toggleArmor = typeof props.toggleArmor === "function" ? props.toggleArmor : null;
      var armor = typeof useProjection === "function"
        ? useProjection("armor")
        : undefined;

      var enabled = !armor || armor.enabled !== false;
      var paused = !!armor && armor.enabled === false;

      var lastVerdictRef = react.useRef(null);
      var flashUntilRef = react.useRef(0);
      var tickPair = react.useState(0);
      var setTick = tickPair[1];
      var busyPair = react.useState(false);
      var busy = busyPair[0];
      var setBusy = busyPair[1];
      var errPair = react.useState(null);
      var error = errPair[0];
      var setError = errPair[1];

      react.useEffect(function () {
        var styleEl = null;
        if (!document.getElementById("dsh-armor-css")) {
          styleEl = document.createElement("style");
          styleEl.id = "dsh-armor-css";
          styleEl.textContent = ANIM_CSS;
          document.head.appendChild(styleEl);
        }
        return function () { if (styleEl) styleEl.remove(); };
      }, []);

      // 投影值变化时：记录判定并开启 2.5s 展示窗口（纯前端计时）
      react.useEffect(function () {
        var v = armor && armor.verdict ? armor.verdict : null;
        if (v !== lastVerdictRef.current) {
          lastVerdictRef.current = v;
          if (v) flashUntilRef.current = Date.now() + FLASH_MS;
          setTick(Date.now());
        }
      }, [armor]);

      var running = !paused && !!(armor && armor.running);
      var words = armor && Array.isArray(armor.words) ? armor.words : [];
      var showVerdict = !paused && !running && lastVerdictRef.current !== null &&
        Date.now() < flashUntilRef.current;

      var text = paused ? "破甲已关闭" : "破甲已开启";
      var dotStyle = paused ? DOT_OFF_STYLE : Object.assign({}, DOT_STYLE);
      var badgeStyle = paused ? Object.assign({}, BADGE_OFF_STYLE) : Object.assign({}, BADGE_STYLE);

      if (busy) {
        text = "切换中…";
      } else if (!paused) {
        if (running) {
          dotStyle.animation = "dshArmorPulse 1.2s ease-in-out infinite";
          text = "思考中…";
        } else if (showVerdict) {
          if (lastVerdictRef.current === "pass") {
            text = "✓ 通过";
            badgeStyle.animation = "dshArmorFlash 1.2s ease";
          } else {
            text = "✗ " + (words[0] || "拒绝话术");
            badgeStyle.animation = "dshArmorFlash 1.6s ease";
            badgeStyle.borderColor = "rgba(239, 68, 68, 0.5)";
            badgeStyle.background = "rgba(239, 68, 68, 0.12)";
            dotStyle.background = "#ef4444";
          }
        }
      }

      var onClick = null;
      if (toggleArmor !== null && !busy) {
        onClick = function () {
          // 点击 = 发送裸 /armor，翻转完全由服务端按已提交状态裁决（客户端状态不参与）
          setBusy(true);
          setError(null);
          toggleArmor().then(function (failure) {
            setBusy(false);
            if (failure) setError(failure);
          }, function (reason) {
            setBusy(false);
            setError(reason instanceof Error ? reason.message : String(reason));
          });
        };
      }

      return react.createElement(
        "div",
        { style: WRAP_STYLE },
        react.createElement(
          "button",
          {
            type: "button",
            style: badgeStyle,
            "data-armor": paused ? "off" : "on",
            title: paused
              ? "破甲已关闭 · 点击开启（/armor on）"
              : "破甲已开启 · 点击关闭（/armor off）",
            onClick: onClick,
            disabled: busy
          },
          react.createElement("span", { style: dotStyle }),
          react.createElement("span", null, text),
          error !== null && react.createElement("span", { title: error, style: { color: "#ef4444", marginLeft: "2px" } }, "!")
        )
      );
    }

    function apply(ctx) {
      ctx.slots.inject("conversation.input.dock", () =>
        ctx.slots.register({
          name: "conversation.input.dock",
          id: "armor",
          order: 30,
          inject: (sessionId) => ({
            toggleArmor: async () => {
              const result = await ctx.remote.commands.execute(sessionId, "/armor", []);
              if (!result.ok) return result.error ? result.error.message + " (" + result.error.code + ")" : "command failed";
              if (result.value === void 0) return "unknown command: /armor";
              return null;
            }
          })
        }, ArmorDock)
      );
    }

    exports.name = "dsh-infinite-gen-2";
    exports.inject = inject;
    exports.apply = apply;
    return module.exports;
  }
});