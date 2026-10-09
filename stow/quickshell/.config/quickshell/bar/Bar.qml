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

            // 1.1 發行版標誌島嶼 (帶懸浮微抬升與光圈反饋)
            Rectangle {
                id: logoIsland
                implicitHeight: Theme.barHeight
                implicitWidth: Theme.barHeight + 2
                radius: Theme.radiusIsland
                color: logoMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard
                border.width: 1
                border.color: logoMouse.containsMouse ? Theme.borderActiveColor : Theme.borderColor

                scale: logoMouse.containsMouse ? 1.05 : 1.0
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰣇" // 截圖同款標誌 (Arch / Distro)
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    color: logoMouse.containsMouse ? Theme.accentPurple : Theme.textPrimary
                    Behavior on color { ColorAnimation { duration: 140 } }
                }

                MouseArea {
                    id: logoMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWindow.openLauncher()
                }
            }

            // 1.2 工作區島嶼 [ 1 | 2 | 3 ] (帶平滑水平滑動高光光標 Fluid Workspace Glider)
            Rectangle {
                id: wsIsland
                implicitHeight: Theme.barHeight
                radius: Theme.radiusIsland
                color: Theme.bgCard
                border.width: 1
                border.color: Theme.borderColor

                implicitWidth: wsContainer.width + 12

                Item {
                    id: wsContainer
                    anchors.centerIn: parent
                    width: wsRow.implicitWidth
                    height: 22

                    // 絲滑滑動的高光方塊光標 (Sliding Cursor)
                    Rectangle {
                        id: wsCursor
                        width: 22
                        height: 22
                        radius: Theme.radiusItem
                        color: Theme.textPrimary
                        z: 1

                        // 自動計算聚焦工作區的精確 x 軸偏移
                        x: {
                            var targetX = 0
                            for (var i = 0; i < niriService.workspaces.length; i++) {
                                if (niriService.workspaces[i].is_focused) {
                                    targetX = i * (22 + 4)
                                    break
                                }
                            }
                            return targetX
                        }

                        Behavior on x {
                            NumberAnimation { duration: 190; easing.type: Easing.OutCubic }
                        }
                    }

                    RowLayout {
                        id: wsRow
                        anchors.fill: parent
                        spacing: 4
                        z: 2

                        Repeater {
                            model: niriService.workspaces

                            Item {
                                id: wsItem
                                implicitWidth: 22
                                implicitHeight: 22

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.idx.toString()
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.bold: modelData.is_focused
                                    color: modelData.is_focused ? Theme.textDark : (wsItemMouse.containsMouse ? Theme.textPrimary : Theme.textMuted)
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    id: wsItemMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: niriService.switchWorkspace(modelData.idx)
                                }
                            }
                        }
                    }
                }
            }

            // 1.3 目前焦點視窗標題島嶼 (帶平滑彈性展開/收縮 Fluid Morphing)
            Rectangle {
                id: windowTitleIsland
                implicitHeight: Theme.barHeight
                radius: Theme.radiusIsland
                color: Theme.bgCard
                border.width: 1
                border.color: Theme.borderColor
                clip: true

                visible: implicitWidth > 0
                implicitWidth: niriService.activeWindowTitle !== "" ? Math.min(240, windowTitleRow.implicitWidth + 24) : 0
                opacity: niriService.activeWindowTitle !== "" ? 1.0 : 0.0

                Behavior on implicitWidth {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                }

                RowLayout {
                    id: windowTitleRow
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

            // 1.4 音樂播放島嶼 (帶動態跳動音訊頻譜微動效 Live Equalizer & Fluid Morphing)
            Rectangle {
                id: mediaIsland
                implicitHeight: Theme.barHeight
                radius: Theme.radiusIsland
                color: mediaMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard
                border.width: 1
                border.color: mediaMouse.containsMouse ? Theme.borderActiveColor : Theme.borderColor
                clip: true

                visible: implicitWidth > 0
                implicitWidth: mprisService.trackText !== "" ? Math.min(270, mediaRow.implicitWidth + 22) : 0
                opacity: mprisService.trackText !== "" ? 1.0 : 0.0

                Behavior on implicitWidth {
                    NumberAnimation { duration: 270; easing.type: Easing.OutCubic }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
                }

                scale: mediaMouse.containsMouse ? 1.02 : 1.0
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

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

                    // 4 根即時起伏跳動的精巧音訊頻譜條 (Live Equalizer Visualizer)
                    Row {
                        spacing: 2
                        visible: mprisService.isPlaying
                        Layout.alignment: Qt.AlignVCenter
                        height: 12

                        Repeater {
                            model: [
                                { min: 3, max: 12, dur: 420 },
                                { min: 5, max: 15, dur: 310 },
                                { min: 2, max: 10, dur: 520 },
                                { min: 4, max: 13, dur: 370 }
                            ]
                            Rectangle {
                                width: 2
                                radius: 1
                                color: Theme.accentGreen
                                height: modelData.min
                                anchors.bottom: parent.bottom

                                SequentialAnimation on height {
                                    loops: Animation.Infinite
                                    running: mprisService.isPlaying
                                    NumberAnimation { to: modelData.max; duration: modelData.dur; easing.type: Easing.InOutQuad }
                                    NumberAnimation { to: modelData.min; duration: modelData.dur; easing.type: Easing.InOutQuad }
                                }
                            }
                        }
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
        // 2. 中央島嶼 (置中時間與日期: 06:22 AM | Sun, 30-Mar，帶懸浮微動效)
        // =========================================================================
        Rectangle {
            id: clockIsland
            anchors.centerIn: parent
            implicitHeight: Theme.barHeight
            implicitWidth: clockRow.implicitWidth + 24
            radius: Theme.radiusIsland
            color: clockMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard
            border.width: 1
            border.color: clockMouse.containsMouse ? Theme.borderActiveColor : Theme.borderColor

            scale: clockMouse.containsMouse ? 1.03 : 1.0
            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

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

            MouseArea {
                id: clockMouse
                anchors.fill: parent
                hoverEnabled: true
            }
        }

        // =========================================================================
        // 3. 右側島嶼群組 (通知徽章 + 天氣 + 硬體狀態群組)
        // =========================================================================
        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // 3.1 通知徽章島嶼 (截圖同款: 󰂚 38，帶微呼吸脈衝動效)
            Rectangle {
                id: notifIsland
                implicitHeight: Theme.barHeight
                implicitWidth: notifRow.implicitWidth + 18
                radius: Theme.radiusIsland
                color: notifMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard
                border.width: 1
                border.color: notifMouse.containsMouse ? Theme.borderActiveColor : Theme.borderColor

                scale: notifMouse.containsMouse ? 1.04 : 1.0
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

                RowLayout {
                    id: notifRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        id: bellIcon
                        text: "󰂚"
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        color: Theme.accentYellow

                        // 通知大於 0 時的柔和呼吸動效
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: systemService.notificationCount > 0
                            NumberAnimation { to: 0.55; duration: 1200; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 1.00; duration: 1200; easing.type: Easing.InOutQuad }
                        }
                    }

                    Text {
                        text: systemService.notificationCount.toString()
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.textPrimary
                    }
                }

                MouseArea {
                    id: notifMouse
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }

            // 3.2 天氣島嶼 (截圖同款: 󰖙 Sunny, -14°C)
            Rectangle {
                id: weatherIsland
                implicitHeight: Theme.barHeight
                implicitWidth: weatherRow.implicitWidth + 20
                radius: Theme.radiusIsland
                color: weatherMouse.containsMouse ? Theme.bgCardHover : Theme.bgCard
                border.width: 1
                border.color: weatherMouse.containsMouse ? Theme.borderActiveColor : Theme.borderColor

                scale: weatherMouse.containsMouse ? 1.03 : 1.0
                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }

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

                MouseArea {
                    id: weatherMouse
                    anchors.fill: parent
                    hoverEnabled: true
                }
            }

            // 3.3 硬體與快捷群組島嶼 (截圖同款: 󰋋 39% | 󰂄 100% | 󰤨 | 󱄅 | 󰐥)
            Rectangle {
                id: hwIsland
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

                    // 電源按鈕 (帶懸浮旋轉或縮放反饋)
                    Rectangle {
                        implicitWidth: 20
                        implicitHeight: 20
                        radius: 4
                        color: powerMouse.containsMouse ? Theme.bgCardHover : "transparent"
                        scale: powerMouse.containsMouse ? 1.15 : 1.0
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                        Text {
                            anchors.centerIn: parent
                            text: "󰐥"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: powerMouse.containsMouse ? "#ff7b72" : "#f38ba8"
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
