/* 无限二代 (dsh-infinite-gen-2) client half — renders the "破甲已开启" status
 * dock above the composer (conversation.input.dock slot). Loaded by the
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

    var DOCK_STYLE = {
      display: "flex",
      alignItems: "center",
      gap: "8px",
      width: "100%",
      boxSizing: "border-box",
      padding: "6px 14px",
      borderRadius: "10px",
      border: "1px solid rgba(34, 197, 94, 0.35)",
      background: "rgba(34, 197, 94, 0.08)",
      color: "inherit",
      fontSize: "12px",
      lineHeight: "18px",
      fontFamily: "inherit",
      userSelect: "none"
    };
    var DOT_STYLE = {
      width: "8px",
      height: "8px",
      borderRadius: "50%",
      background: "#22c55e",
      boxShadow: "0 0 6px rgba(34, 197, 94, 0.8)",
      flex: "none"
    };

    function ArmorDock() {
      return react.createElement(
        "div",
        { style: DOCK_STYLE, "data-armor": "on", title: "破甲插件已生效" },
        react.createElement("span", { style: DOT_STYLE }),
        react.createElement("span", { style: { fontWeight: 600 } }, "破甲已开启")
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
