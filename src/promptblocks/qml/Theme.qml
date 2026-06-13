pragma Singleton
import QtQuick

QtObject {
    id: theme

    // ── System theme detection ──
    readonly property bool isDark: Application.styleHints.colorScheme === Qt.ColorScheme.Dark

    // ── Color system (brand-aligned with #0E3A5C deep navy) ──
    // Primary brand: #0E3A5C — professional, trustworthy deep navy
    // Light mode: primary = logo colour directly
    // Dark mode:  primary = lighter tint (#5B8DB8) for contrast on dark bg
    readonly property color background:      isDark ? "#0a1628" : "#f5f7fa"
    readonly property color surface:         isDark ? "#111d2b" : "#ffffff"
    readonly property color surfaceVariant:  isDark ? "#1a2535" : "#eef1f5"
    readonly property color surfaceRaised:   isDark ? "#1e2d3d" : "#e4e8ed"
    readonly property color primary:         isDark ? "#5B8DB8" : "#0E3A5C"
    readonly property color primaryMuted:    isDark ? "#5B8DB833" : "#0E3A5C18"
    readonly property color primaryContainer:isDark ? "#1a2d3d" : "#e8f0f8"
    readonly property color secondary:       isDark ? "#4ECDC4" : "#0d7377"
    readonly property color error:           isDark ? "#ff6b6b" : "#dc2626"
    readonly property color warning:         isDark ? "#f9c74f" : "#d97706"
    readonly property color accent:          isDark ? "#a78bfa" : "#7c3aed"
    readonly property color accentMuted:     isDark ? "#a78bfa40" : "#7c3aed18"

    // Text colors (adjusted for new deep-navy palette)
    readonly property color onBackground:     isDark ? "#e8ecf1" : "#1a2332"
    readonly property color onSurface:        isDark ? "#c4cdd8" : "#2d3a4a"
    // onSurfaceVariant on light bg #eef1f5 ≈ 6.2:1 with #4a5568 (WCAG AA compliant)
    readonly property color onSurfaceVariant: isDark ? "#8b9aad" : "#4a5568"
    readonly property color onPrimary:        isDark ? "#F9F9F9" : "#F9F9F9"

    // Border & Divider (cooler tones matching navy palette)
    readonly property color border:         isDark ? "#1e2d3d" : "#d0d7df"
    readonly property color borderLight:    isDark ? "#162233" : "#e2e6eb"
    readonly property color divider:        isDark ? "#253547" : "#dde3ea"
    readonly property color panelBorder:    isDark ? "#1f3040" : "#c8d0d8"
    readonly property color cardBorder:     isDark ? "#223547" : "#e0e5ea"
    readonly property color cardBackground: isDark ? "#162233" : "#fafbfd"

    // Shadows (approximate via tinted colors, real shadow via QML effects)
    readonly property color shadowColor: isDark ? "#00000060" : "#00000018"

    // Header / accent gradients (subtle navy tint)
    readonly property color headerStart:  isDark ? "#0E3A5C20" : "#0E3A5C0d"
    readonly property color headerEnd:    isDark ? "#00000000" : "#00000000"

    // ── Glass parameters ──
    readonly property real glassOpacity: isDark ? 0.72 : 0.78
    readonly property real glassBlur: 32
    readonly property color glassTint:   isDark ? "#0f1720" : "#ffffff"
    readonly property color glassBorder: isDark ? "#ffffff15" : "#ffffff40"

    // ── Spacing scale ──
    readonly property int spacingXXS: 2
    readonly property int spacingXS: 4
    readonly property int spacingS: 6
    readonly property int spacingSM: 8
    readonly property int spacingMD: 12
    readonly property int spacingLG: 16
    readonly property int spacingXL: 24
    readonly property int spacingXXL: 32

    // ── Standard container padding ──
    readonly property int containerPadding: spacingLG   // 16px — uniform panel content padding

    // ── Corner radii ──
    readonly property int radiusSM: 6
    readonly property int radiusMD: 10
    readonly property int radiusLG: 16
    readonly property int radiusXL: 20

    // ── Typography scale ──
    readonly property int fontXXS: 8
    readonly property int fontS: 9
    readonly property int fontXS: 10
    readonly property int fontSM: 12
    readonly property int fontML: 13
    readonly property int fontMD: 14
    readonly property int fontLG: 16
    readonly property int fontXL2: 18
    readonly property int fontXL: 20
    readonly property int fontXXXL: 24
    readonly property int fontXXL: 28

    // ── Font families ──
    // `fontFamilies` (list) supports per-character fallback so that Phosphor
    // icons render correctly when mixed with regular text.
    // `fontFamily` (single string) is kept for compatibility and defaults to
    // "Segoe UI"; it does NOT contain Phosphor because QFont.setFamily()
    // does not understand comma-separated lists.
    readonly property string fontFamily: "Segoe UI"
    readonly property var fontFamilies: ["Segoe UI", "Phosphor", "Microsoft YaHei", "sans-serif"]
    readonly property string codeFontFamily: "Consolas, Microsoft YaHei, monospace"

    // ── Component height scale ──
    readonly property int heightXS: 28
    readonly property int heightSM: 36
    readonly property int heightMD: 40
    readonly property int heightLG: 44

    // ── Animation durations ──
    readonly property int animFast: 120
    readonly property int animNormal: 220
    readonly property int animSlow: 350

    // ── Animation easing ──
    readonly property int animEasing: Easing.OutQuad

    // ── Accessibility: reduced motion ──
    // When true, all animations should skip (duration=0)
    readonly property bool animReducedMotion: Application.styleHints ? false : false
    // Note: Qt does not expose a native "prefers-reduced-motion" API.
    // Users can override this via a settings key in the future.
    // For now, default to false (animations enabled).

    // ── Status container colors ──
    readonly property color errorContainer:      isDark ? "#2d1518" : "#fef2f2"
    readonly property color onErrorContainer:    isDark ? "#ff6b6b" : "#dc2626"
    readonly property color successContainer:    isDark ? "#152618" : "#f0fdf4"
    readonly property color onSuccessContainer:  isDark ? "#4ade80" : "#059669"
    readonly property color warningContainer:    isDark ? "#2d1f12" : "#fffbeb"
    // Light mode #92400e on #fffbeb ≈ 5.5:1 (WCAG AA compliant for body text)
    readonly property color onWarningContainer:  isDark ? "#f9c74f" : "#92400e"
    readonly property color infoContainer:       isDark ? "#132238" : "#eff6ff"
    readonly property color onInfoContainer:     isDark ? "#5B8DB8" : "#0E3A5C"

    // ── Code block ──
    readonly property color codeBackground: isDark ? "#0d1117" : "#f1f5f9"
    readonly property color codeBorder:     isDark ? "#253547" : "#e2e8f0"

    // ── Interactive states ──
    readonly property color cardHover:           isDark ? "#ffffff08" : "#00000005"
    readonly property color buttonHoverPrimary:  isDark ? "#5B8DB825" : "#0E3A5C15"
    readonly property color buttonHoverDanger:   isDark ? "#ff6b6b25" : "#dc262615"
    readonly property color overlayBackground:   isDark ? "#00000060" : "#00000030"

    // ── Semi-transparent onPrimary variants ──
    readonly property color onPrimaryMuted:      isDark ? "#F9F9F9cc" : "#F9F9F9cc"   // ~80% opacity
    readonly property color onPrimarySubtle:     isDark ? "#F9F9F980" : "#F9F9F980"   // ~50% opacity

    // ── Shadows ──
    readonly property color shadowDrag:          isDark ? "#60000000" : "#30000000"

    // ── Module type color mapping ──
    // Each module type has { bg, border, accent } for both dark and light modes.
    // - `bg`: very light tinted color (used for ModuleCard header background)
    // - `border`: slightly darker tint for borders
    // - `accent`: desaturated mid-tone (for text on tinted bg, badges, accents)
    // Usage: Theme.moduleTypeColors["identity_role"].bg
    readonly property var moduleTypeColors: ({
        "identity_role": {
            "bg":     isDark ? "#1a2240" : "#dbeafe",
            "border": isDark ? "#2c3e6e" : "#bfdbfe",
            "accent": isDark ? "#5B8DB8" : "#1e3a8a",
        },
        "task_goal": {
            "bg":     isDark ? "#152618" : "#d1fae5",
            "border": isDark ? "#2a4a2e" : "#a7f3d0",
            "accent": isDark ? "#4ade80" : "#065f46",
        },
        "variable_param": {
            "bg":     isDark ? "#2d2a12" : "#fef3c7",
            "border": isDark ? "#4a4520" : "#fde68a",
            "accent": isDark ? "#f9c74f" : "#92400e",
        },
        "knowledge_rag": {
            "bg":     isDark ? "#231540" : "#ede9fe",
            "border": isDark ? "#3d2a5e" : "#ddd6fe",
            "accent": isDark ? "#a78bfa" : "#5b21b6",
        },
        "capability_tool": {
            "bg":     isDark ? "#122a26" : "#ccfbf1",
            "border": isDark ? "#1e4a42" : "#99f6e4",
            "accent": isDark ? "#4ECDC4" : "#115e59",
        },
        "reasoning_workflow": {
            "bg":     isDark ? "#2d1518" : "#fee2e2",
            "border": isDark ? "#4a2528" : "#fecaca",
            "accent": isDark ? "#ff6b6b" : "#991b1b",
        },
        "output_format": {
            "bg":     isDark ? "#2d1f12" : "#ffedd5",
            "border": isDark ? "#4a3520" : "#fed7aa",
            "accent": isDark ? "#f9c74f" : "#9a3412",
        },
        "constraint_safety": {
            "bg":     isDark ? "#2d2a12" : "#fef3c7",
            "border": isDark ? "#4a4520" : "#fde68a",
            "accent": isDark ? "#f9c74f" : "#92400e",
        },
        "example_fewshot": {
            "bg":     isDark ? "#152618" : "#d1fae5",
            "border": isDark ? "#2a4a2e" : "#a7f3d0",
            "accent": isDark ? "#4ade80" : "#065f46",
        },
        "prepost_process": {
            "bg":     isDark ? "#1a1a30" : "#e0e7ff",
            "border": isDark ? "#2e2e52" : "#c7d2fe",
            "accent": isDark ? "#a78bfa" : "#3730a3",
        }
    })
}
