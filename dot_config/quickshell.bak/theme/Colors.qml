pragma Singleton
import QtQuick
import "."

QtObject {
    id: root

    readonly property bool dark: ThemeState.isDarkMode

    // 底色
    readonly property color base: dark ? "#1e1e2e" : "#eff1f5"
    readonly property color mantle: dark ? "#181825" : "#e6e9ef"
    readonly property color crust: dark ? "#11111b" : "#dce0e8"
    readonly property color surface0: dark ? "#313244" : "#ccd0da"
    readonly property color surface1: dark ? "#45475a" : "#bcc0cc"
    readonly property color surface2: dark ? "#585b70" : "#acb0be"

    // 文字色彩
    readonly property color text: dark ? "#cdd6f4" : "#4c4f69"
    readonly property color subtext: dark ? "#a6adc8" : "#6c6f85"
    readonly property color overlay: dark ? "#6c7086" : "#9ca0b0"

    // 強調與功能色
    readonly property color lavender: dark ? "#b4befe" : "#7287fd"
    readonly property color blue: dark ? "#89b4fa" : "#1e66f5"
    readonly property color sapphire: dark ? "#74c7ec" : "#209fb5"
    readonly property color green: dark ? "#a6e3a1" : "#40a02b"
    readonly property color yellow: dark ? "#f9e2af" : "#df8e1d"
    readonly property color peach: dark ? "#fab387" : "#fe640b"
    readonly property color red: dark ? "#f38ba8" : "#d20f39"
    readonly property color mauve: dark ? "#cba6f7" : "#8839ef"

    // 毛玻璃 (Glassmorphism) 核心色彩定義
    readonly property color glassBackground: dark ? Qt.rgba(0.12, 0.12, 0.18, 0.72)
                                                  : Qt.rgba(0.94, 0.95, 0.96, 0.80)

    readonly property color glassCard: dark ? Qt.rgba(0.19, 0.20, 0.27, 0.65)
                                            : Qt.rgba(0.85, 0.87, 0.91, 0.70)

    readonly property color glassCardHover: dark ? Qt.rgba(0.24, 0.25, 0.33, 0.80)
                                                 : Qt.rgba(0.78, 0.80, 0.85, 0.85)

    readonly property color glassBorder: dark ? Qt.rgba(0.71, 0.75, 1.0, 0.18)
                                              : Qt.rgba(0.45, 0.53, 0.99, 0.22)

    readonly property color glassShadow: dark ? Qt.rgba(0.0, 0.0, 0.0, 0.35)
                                              : Qt.rgba(0.0, 0.0, 0.0, 0.10)

    readonly property int cornerRadius: 14
    readonly property int cornerRadiusSmall: 8
}
