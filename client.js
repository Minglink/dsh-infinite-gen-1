/* 无限二代 (dsh-infinite-gen-2) client half — renders the compact "破甲已开启"
 * badge dock above the composer (conversation.input.dock slot). Loaded by the
 * harness browser loader as `/plugins/dsh-infinite-gen-2/client.js`.
 */
window.__ModuleLoader__.load({
  id: "dsh-infinite-gen-2",
  factory: (require) => {
    var module = { exports: {} };
    var exports = module.exports;
    Object.defineProperty(exports, Symbol.toStringTag, { value: "Module" });

    var react = require("react");

    var inject = ["slots"];

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

    var WRAP_STYLE = {
      display: "flex",
      justifyContent: "center",
      width: "100%"
    };

    function ArmorDock() {
      return react.createElement(
        "div",
        { style: WRAP_STYLE },
        react.createElement(
          "div",
          { style: BADGE_STYLE, "data-armor": "on", title: "破甲插件已生效" },
          react.createElement("span", { style: DOT_STYLE }),
          react.createElement("span", null, "破甲已开启")
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
