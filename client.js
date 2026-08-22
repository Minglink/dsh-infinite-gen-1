/* 无限二代 (dsh-infinite-gen-2) client half — realtime "破甲已开启" badge.
 * Idle: green dot. Thinking: breathing pulse. Turn passed: ✓. Refusal hit:
 * red flash showing the matched word. Polls the host's armorState (300ms).
 */
window.__ModuleLoader__.load({
  id: "dsh-infinite-gen-2",
  factory: (require) => {
    var module = { exports: {} };
    var exports = module.exports;
    Object.defineProperty(exports, Symbol.toStringTag, { value: "Module" });

    var react = require("react");

    var inject = ["slots"];

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
      whiteSpace: "nowrap"
    };
    var DOT_STYLE = {
      width: "6px",
      height: "6px",
      borderRadius: "50%",
      background: "#22c55e",
      flex: "none"
    };

    function ArmorDock(props) {
      var sessionId = props.sessionId || (props.session && props.session.id) || null;
      var statePair = react.useState(null);
      var state = statePair[0];
      var setState = statePair[1];

      react.useEffect(function () {
        var alive = true;
        var styleEl = null;
        if (!document.getElementById("dsh-armor-css")) {
          styleEl = document.createElement("style");
          styleEl.id = "dsh-armor-css";
          styleEl.textContent = ANIM_CSS;
          document.head.appendChild(styleEl);
        }
        if (!sessionId) {
          return function () { alive = false; if (styleEl) styleEl.remove(); };
        }
        var tick = function () {
          host.call("armorState", { sessionId: sessionId })
            .then(function (s) { if (alive) setState(s); })
            .catch(function () {});
        };
        tick();
        var timer = setInterval(tick, 300);
        return function () {
          alive = false;
          clearInterval(timer);
          if (styleEl) styleEl.remove();
        };
      }, [sessionId]);

      var running = !!(state && state.running);
      var verdict = state ? state.verdict : null;
      var words = state && Array.isArray(state.words) ? state.words : [];

      var text = "破甲已开启";
      var dotStyle = Object.assign({}, DOT_STYLE);
      var badgeStyle = Object.assign({}, BADGE_STYLE);

      if (running) {
        dotStyle.animation = "dshArmorPulse 1.2s ease-in-out infinite";
        text = "思考中…";
      } else if (verdict === "pass") {
        text = "✓ 通过";
        badgeStyle.animation = "dshArmorFlash 1.2s ease";
      } else if (verdict === "refusal" || verdict === "fallback") {
        text = "✗ " + (words[0] || "拒绝话术");
        badgeStyle.animation = "dshArmorFlash 1.6s ease";
        badgeStyle.borderColor = "rgba(239, 68, 68, 0.5)";
        badgeStyle.background = "rgba(239, 68, 68, 0.12)";
        dotStyle.background = "#ef4444";
      }

      return react.createElement(
        "div",
        { style: WRAP_STYLE },
        react.createElement(
          "div",
          { style: badgeStyle, "data-armor": "on", title: "破甲插件已生效 · 实时状态" },
          react.createElement("span", { style: dotStyle }),
          react.createElement("span", null, text)
        )
      );
    }

    function apply(ctx) {
      ctx.slots.inject("conversation.input.dock", () =>
        ctx.slots.register({
          name: "conversation.input.dock",
          id: "armor",
          order: 30
        }, ArmorDock)
      );
    }

    exports.name = "dsh-infinite-gen-2";
    exports.inject = inject;
    exports.apply = apply;
    return module.exports;
  }
});
