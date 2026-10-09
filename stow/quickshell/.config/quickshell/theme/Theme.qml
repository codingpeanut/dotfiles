pragma Singleton
import QtQuick

QtObject {
    // 截圖同款深色黑炭微透底色 (Frosted Obsidian)
    readonly property color bgTranslucent: Qt.rgba(20/255, 18/255, 24/255, 0.82)
    readonly property color bgCard:        Qt.rgba(26/255, 24/255, 32/255, 0.90)
    readonly property color bgCardHover:   Qt.rgba(40/255, 36/255, 50/255, 0.95)
    readonly property color bgSelected:    Qt.rgba(48/255, 44/255, 60/255, 0.95)

    // 細緻高光邊框 (1px 描邊)
    readonly property color borderColor:      Qt.rgba(208/255, 188/255, 255/255, 0.16)
    readonly property color borderActiveColor: Qt.rgba(208/255, 188/255, 255/255, 0.45)

    // 文字色彩層級
    readonly property color textPrimary:   "#e6e1e5"
    readonly property color textSecondary: "#938f99"
    readonly property color textMuted:     "#79747e"
    readonly property color textDark:      "#141218"

    // 截圖中的重點配色
    readonly property color accentMint:   "#78d8a3"  // Rofi APPS 按鈕薄荷綠
    readonly property color accentYellow: "#f9e2af"  // 通知徽章暖黃
    readonly property color accentPurple: "#d0bcff"  // 工作區高光淡紫
    readonly property color accentBlue:   "#89b4fa"  // 視窗標題淡藍
    readonly property color accentGreen:  "#a6e3a1"  // 狀態正常綠

    // 圓角與幾何比例 (克制規整，拒絕肥大橢圓)
    readonly property int radiusIsland:  10  // 頂欄模組微圓角
    readonly property int radiusItem:     6  // 工作區按鈕微圓角
    readonly property int radiusModal:   16  // 啟動器與彈窗大圓角
    readonly property int barHeight:     30  // 頂欄模組高度 (小巧精緻)

    // 字型
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
}
