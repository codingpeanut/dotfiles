import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"

PanelWindow {
    id: ccWindow

    property bool isOpen: false

    anchors {
        top: true
        right: true
    }

    margins {
        top: 50
        right: 14
    }

    width: 320
    height: contentCard.implicitHeight + 24
    color: "transparent"

    visible: isOpen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // 狀態變數
    property bool wifiEnabled: true
    property bool btEnabled: true
    property bool nightLightEnabled: false
    property int currentVolume: 60
    property int currentBrightness: 70

    // 背景卡片 (毛玻璃效果)
    Rectangle {
        id: contentCard
        anchors.fill: parent
        radius: Colors.cornerRadius
        color: Colors.glassBackground
        border.color: Colors.glassBorder
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            // -----------------------------------------------------
            // 頂部列：使用者問候與快速系統電源按鈕
            // -----------------------------------------------------
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "控制中心"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: Colors.text
                    Layout.fillWidth: true
                }

                // 螢幕鎖定 (Win+L / Hyprlock)
                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: lockMouse.containsMouse ? Colors.glassCardHover : Colors.glassCard
                    border.color: Colors.glassBorder
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "🔒"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: lockMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.exec(["hyprlock"]);
                            ccWindow.isOpen = false;
                        }
                    }
                }

                // 睡眠待命
                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: suspMouse.containsMouse ? Colors.glassCardHover : Colors.glassCard
                    border.color: Colors.glassBorder
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "🌙"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: suspMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.exec(["systemctl", "suspend"]);
                            ccWindow.isOpen = false;
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Colors.surface0
            }

            // -----------------------------------------------------
            // 快速開關磁貼 (Wi-Fi, 藍牙, 日夜模式, 護眼模式)
            // -----------------------------------------------------
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                // 1. Wi-Fi
                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    radius: Colors.cornerRadiusSmall
                    color: ccWindow.wifiEnabled ? Colors.lavender : Colors.glassCard
                    border.color: Colors.glassBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Text {
                            text: "📶"
                            font.pixelSize: 16
                        }
                        Column {
                            Layout.fillWidth: true
                            Text {
                                text: "Wi-Fi"
                                font.pixelSize: 12
                                font.bold: true
                                color: ccWindow.wifiEnabled ? Colors.crust : Colors.text
                            }
                            Text {
                                text: ccWindow.wifiEnabled ? "已連線" : "已關閉"
                                font.pixelSize: 10
                                color: ccWindow.wifiEnabled ? Colors.surface0 : Colors.subtext
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ccWindow.wifiEnabled = !ccWindow.wifiEnabled;
                            Quickshell.exec(["nmcli", "radio", "wifi", ccWindow.wifiEnabled ? "on" : "off"]);
                        }
                    }
                }

                // 2. 藍牙
                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    radius: Colors.cornerRadiusSmall
                    color: ccWindow.btEnabled ? Colors.lavender : Colors.glassCard
                    border.color: Colors.glassBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Text {
                            text: "ᛒ"
                            font.pixelSize: 16
                            color: ccWindow.btEnabled ? Colors.crust : Colors.text
                        }
                        Column {
                            Layout.fillWidth: true
                            Text {
                                text: "藍牙"
                                font.pixelSize: 12
                                font.bold: true
                                color: ccWindow.btEnabled ? Colors.crust : Colors.text
                            }
                            Text {
                                text: ccWindow.btEnabled ? "開啟" : "已關閉"
                                font.pixelSize: 10
                                color: ccWindow.btEnabled ? Colors.surface0 : Colors.subtext
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ccWindow.btEnabled = !ccWindow.btEnabled;
                            Quickshell.exec(["bluetoothctl", "power", ccWindow.btEnabled ? "on" : "off"]);
                        }
                    }
                }

                // 3. Catppuccin 日夜雙模切換 (Mocha ⇄ Latte)
                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    radius: Colors.cornerRadiusSmall
                    color: Colors.glassCard
                    border.color: Colors.lavender
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Text {
                            text: ThemeState.isDarkMode ? "🌌" : "☀️"
                            font.pixelSize: 16
                        }
                        Column {
                            Layout.fillWidth: true
                            Text {
                                text: "主題模式"
                                font.pixelSize: 12
                                font.bold: true
                                color: Colors.text
                            }
                            Text {
                                text: ThemeState.isDarkMode ? "Mocha 深色" : "Latte 淺色"
                                font.pixelSize: 10
                                color: Colors.lavender
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ThemeState.toggleTheme()
                    }
                }

                // 4. 夜間護眼模式 (wlsunset)
                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    radius: Colors.cornerRadiusSmall
                    color: ccWindow.nightLightEnabled ? Colors.peach : Colors.glassCard
                    border.color: Colors.glassBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8
                        Text {
                            text: "🕯️"
                            font.pixelSize: 16
                        }
                        Column {
                            Layout.fillWidth: true
                            Text {
                                text: "夜間護眼"
                                font.pixelSize: 12
                                font.bold: true
                                color: ccWindow.nightLightEnabled ? Colors.crust : Colors.text
                            }
                            Text {
                                text: ccWindow.nightLightEnabled ? "溫暖色調" : "標準色溫"
                                font.pixelSize: 10
                                color: ccWindow.nightLightEnabled ? Colors.surface0 : Colors.subtext
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ccWindow.nightLightEnabled = !ccWindow.nightLightEnabled;
                            if (ccWindow.nightLightEnabled) {
                                Quickshell.exec(["wlsunset", "-t", "4000"]);
                            } else {
                                Quickshell.exec(["killall", "wlsunset"]);
                            }
                        }
                    }
                }
            }

            // -----------------------------------------------------
            // 音量與螢幕亮度滑桿 (Glass Sliders)
            // -----------------------------------------------------
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                // 音量滑桿
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text { text: "🔊"; font.pixelSize: 13 }
                    Slider {
                        Layout.fillWidth: true
                        from: 0
                        to: 100
                        value: ccWindow.currentVolume
                        onMoved: {
                            ccWindow.currentVolume = Math.round(value);
                            Quickshell.exec(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (value / 100).toFixed(2)]);
                        }
                    }
                    Text {
                        text: ccWindow.currentVolume + "%"
                        font.pixelSize: 11
                        color: Colors.subtext
                    }
                }

                // 亮度滑桿 (Dell Latitude 7420)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Text { text: "🔆"; font.pixelSize: 13 }
                    Slider {
                        Layout.fillWidth: true
                        from: 5
                        to: 100
                        value: ccWindow.currentBrightness
                        onMoved: {
                            ccWindow.currentBrightness = Math.round(value);
                            Quickshell.exec(["brightnessctl", "set", Math.round(value) + "%"]);
                        }
                    }
                    Text {
                        text: ccWindow.currentBrightness + "%"
                        font.pixelSize: 11
                        color: Colors.subtext
                    }
                }
            }
        }
    }
}
