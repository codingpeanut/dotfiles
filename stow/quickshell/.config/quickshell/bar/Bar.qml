import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"
import "../services"

PanelWindow {
    id: barWindow

    // 錨定在螢幕頂部，高度設定為 42px (留出上下邊距 6px，模組高 30px)
    anchors {
        top: true
        left: true
        right: true
    }
    height: 42
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    signal openLauncher()
    signal openPowerMenu()

    required property NiriService niriService
    required property MprisService mprisService
    required property SystemService systemService

    Item {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 6
        anchors.bottomMargin: 6

        // =========================================================================
        // 1. 左側島嶼群組 (Logo + 工作區 + 視窗標題 + 音樂播放)
        // =========================================================================
        RowLayout {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // 1.1 發行版標誌島嶼 (點擊開啟雙欄啟動器)
            Rectangle {
                implicitHeight: Theme.barHeight
                implicitWidth: Theme.barHeight + 2
                radius: Theme.radiusIsland
                color: logoMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard
                border.width: 1
                border.color: logoMouse.containsMouse ? Theme.borderActiveColor : Theme.borderColor

                Text {
                    anchors.centerIn: parent
                    text: "󰣇" // 截圖同款標誌 (Arch / Distro)
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    color: Theme.textPrimary
                }

                MouseArea {
                    id: logoMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWindow.openLauncher()
                }
            }

            // 1.2 工作區島嶼 [ 1 | 2 | 3 ]
            Rectangle {
                implicitHeight: Theme.barHeight
                radius: Theme.radiusIsland
                color: Theme.bgCard
                border.width: 1
                border.color: Theme.borderColor

                // 內縮邊距
                implicitWidth: wsRow.implicitWidth + 12

                RowLayout {
                    id: wsRow
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: niriService.workspaces

                        Rectangle {
                            id: wsItem
                            implicitWidth: 22
                            implicitHeight: 22
                            radius: Theme.radiusItem

                            // 選中項像截圖一樣帶有精緻白色/淺紫方塊底
                            color: modelData.is_focused ? Theme.textPrimary : (wsMouse.containsMouse ? Theme.bgCardHover : "transparent")
                            border.width: modelData.is_focused ? 0 : 0

                            Text {
                                anchors.centerIn: parent
                                text: modelData.idx.toString()
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.bold: modelData.is_focused
                                color: modelData.is_focused ? Theme.textDark : (wsMouse.containsMouse ? Theme.textPrimary : Theme.textMuted)
                            }

                            MouseArea {
                                id: wsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: niriService.switchWorkspace(modelData.idx)
                            }
                        }
                    }
                }
            }

            // 1.3 目前焦點視窗標題島嶼
            Rectangle {
                visible: niriService.activeWindowTitle !== ""
                implicitHeight: Theme.barHeight
                implicitWidth: Math.min(240, windowTitleText.implicitWidth + 24)
                radius: Theme.radiusIsland
                color: Theme.bgCard
                border.width: 1
                border.color: Theme.borderColor

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 6

                    Text {
                        text: ""
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.accentBlue
                    }

                    Text {
                        id: windowTitleText
                        Layout.fillWidth: true
                        text: niriService.activeWindowTitle
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                    }
                }
            }

            // 1.4 音樂播放島嶼 (截圖同款:  Dog - how to lock in hard)
            Rectangle {
                visible: mprisService.trackText !== ""
                implicitHeight: Theme.barHeight
                implicitWidth: Math.min(260, mediaRow.implicitWidth + 20)
                radius: Theme.radiusIsland
                color: mediaMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard
                border.width: 1
                border.color: mediaMouse.containsMouse ? Theme.borderActiveColor : Theme.borderColor

                RowLayout {
                    id: mediaRow
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 6

                    Text {
                        text: mprisService.playerIcon
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.accentGreen
                    }

                    Text {
                        Layout.fillWidth: true
                        text: mprisService.trackText
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    id: mediaMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mprisService.togglePlay()
                }
            }
        }

        // =========================================================================
        // 2. 中央島嶼 (置中時間與日期: 06:22 AM | Sun, 30-Mar)
        // =========================================================================
        Rectangle {
            anchors.centerIn: parent
            implicitHeight: Theme.barHeight
            implicitWidth: clockRow.implicitWidth + 24
            radius: Theme.radiusIsland
            color: Theme.bgCard
            border.width: 1
            border.color: Theme.borderColor

            RowLayout {
                id: clockRow
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: systemService.timeString
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.textPrimary
                }

                Text {
                    text: "|"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Theme.textMuted
                }

                Text {
                    text: systemService.dateString
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: Theme.textSecondary
                }
            }
        }

        // =========================================================================
        // 3. 右側島嶼群組 (通知徽章 + 天氣 + 硬體狀態群組)
        // =========================================================================
        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // 3.1 通知徽章島嶼 (截圖同款: 󰂚 38)
            Rectangle {
                implicitHeight: Theme.barHeight
                implicitWidth: notifRow.implicitWidth + 18
                radius: Theme.radiusIsland
                color: Theme.bgCard
                border.width: 1
                border.color: Theme.borderColor

                RowLayout {
                    id: notifRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "󰂚"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.accentYellow
                    }

                    Text {
                        text: systemService.notificationCount.toString()
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.textPrimary
                    }
                }
            }

            // 3.2 天氣島嶼 (截圖同款: 󰖙 Sunny, -14°C)
            Rectangle {
                implicitHeight: Theme.barHeight
                implicitWidth: weatherRow.implicitWidth + 20
                radius: Theme.radiusIsland
                color: Theme.bgCard
                border.width: 1
                border.color: Theme.borderColor

                RowLayout {
                    id: weatherRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: systemService.weatherIcon
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.accentYellow
                    }

                    Text {
                        text: systemService.weatherText
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        color: Theme.textPrimary
                    }
                }
            }

            // 3.3 硬體與快捷群組島嶼 (截圖同款: 󰋋 39% | 󰂄 100% | 󰤨 | 󱄅 | 󰐥)
            Rectangle {
                implicitHeight: Theme.barHeight
                implicitWidth: hwRow.implicitWidth + 20
                radius: Theme.radiusIsland
                color: Theme.bgCard
                border.width: 1
                border.color: Theme.borderColor

                RowLayout {
                    id: hwRow
                    anchors.centerIn: parent
                    spacing: 8

                    // 音量
                    RowLayout {
                        spacing: 4
                        Text {
                            text: systemService.volumeIcon
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: Theme.accentPurple
                        }
                        Text {
                            text: systemService.volumeText
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.textPrimary
                        }
                    }

                    Text { text: "|"; font.family: Theme.fontFamily; font.pixelSize: 10; color: Theme.textMuted }

                    // 電量
                    RowLayout {
                        spacing: 4
                        Text {
                            text: systemService.batteryIcon
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: Theme.accentGreen
                        }
                        Text {
                            text: systemService.batteryText
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.textPrimary
                        }
                    }

                    Text { text: "|"; font.family: Theme.fontFamily; font.pixelSize: 10; color: Theme.textMuted }

                    // Wi-Fi
                    Text {
                        text: systemService.wifiIcon
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.accentBlue
                    }

                    Text { text: "|"; font.family: Theme.fontFamily; font.pixelSize: 10; color: Theme.textMuted }

                    // CPU 負載
                    Text {
                        text: "󱄅"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.accentYellow
                    }

                    Text { text: "|"; font.family: Theme.fontFamily; font.pixelSize: 10; color: Theme.textMuted }

                    // 電源按鈕
                    Rectangle {
                        implicitWidth: 18
                        implicitHeight: 18
                        radius: 4
                        color: powerMouse.containsMouse ? Theme.bgCardHover : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "󰐥"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: "#f38ba8"
                        }

                        MouseArea {
                            id: powerMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: barWindow.openPowerMenu()
                        }
                    }
                }
            }
        }
    }
}
