import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: launcherWindow

    property bool isOpen: false

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: isOpen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function toggle() {
        isOpen = !isOpen;
        if (isOpen) {
            searchField.text = "";
            searchField.forceActiveFocus();
            selectedIndex = 0;
        }
    }

    function close() {
        isOpen = false;
    }

    property int selectedIndex: 0

    // 應用程式清單模型 (常用開發與日常工具)
    ListModel {
        id: defaultAppsModel
        ListElement { name: "Kitty Terminal"; icon: "💻"; exec: "kitty"; desc: "GPU 加速終端機" }
        ListElement { name: "Google Chrome"; icon: "🌐"; exec: "google-chrome"; desc: "網頁瀏覽器" }
        ListElement { name: "Visual Studio Code"; icon: "📝"; exec: "code"; desc: "程式碼編輯器" }
        ListElement { name: "檔案管理員 (Nautilus)"; icon: "📁"; exec: "nautilus"; desc: "瀏覽本機檔案" }
        ListElement { name: "工作管理員 (btop)"; icon: "📊"; exec: "kitty -e btop"; desc: "8GB RAM 與 CPU 資源監控" }
        ListElement { name: "音量設定 (Pavucontrol)"; icon: "🎚️"; exec: "pavucontrol"; desc: "PipeWire 音效進階微調" }
        ListElement { name: "藍牙管理員 (Blueman)"; icon: "ᛒ"; exec: "blueman-manager"; desc: "配對與管理藍牙裝置" }
    }

    // 暗色模糊遮罩 (點擊任意外部區域關閉)
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.0, 0.0, 0.0, 0.45)

        MouseArea {
            anchors.fill: parent
            onClicked: launcherWindow.close()
        }
    }

    // 居中 Spotlight 搜尋卡片
    Rectangle {
        id: searchCard
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.20
        width: 520
        height: cardColumn.implicitHeight + 28
        radius: Colors.cornerRadius
        color: Colors.glassBackground
        border.color: Colors.glassBorder
        border.width: 1

        scale: launcherWindow.isOpen ? 1.0 : 0.92
        opacity: launcherWindow.isOpen ? 1.0 : 0.0

        Behavior on scale {
            NumberAnimation { duration: 180; easing.type: Easing.OutBack }
        }
        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }

        ColumnLayout {
            id: cardColumn
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // 搜尋列
            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: Colors.cornerRadiusSmall
                color: Colors.glassCard
                border.color: Colors.lavender
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: "🔍"
                        font.pixelSize: 15
                    }

                    TextInput {
                        id: searchField
                        Layout.fillWidth: true
                        font.pixelSize: 14
                        color: Colors.text
                        selectionColor: Colors.lavender
                        selectedTextColor: Colors.crust
                        clip: true

                        Text {
                            text: "搜尋應用程式或執行指令..."
                            font.pixelSize: 14
                            color: Colors.overlay
                            visible: !searchField.text
                        }

                        Keys.onEscapePressed: launcherWindow.close()

                        Keys.onDownPressed: {
                            if (selectedIndex < appListView.count - 1) {
                                selectedIndex++;
                            }
                        }

                        Keys.onUpPressed: {
                            if (selectedIndex > 0) {
                                selectedIndex--;
                            }
                        }

                        Keys.onReturnPressed: {
                            if (appListView.count > 0) {
                                let item = defaultAppsModel.get(selectedIndex);
                                if (item && item.exec) {
                                    Quickshell.exec(["sh", "-c", item.exec]);
                                    launcherWindow.close();
                                }
                            } else if (searchField.text.trim().length > 0) {
                                Quickshell.exec(["sh", "-c", searchField.text.trim()]);
                                launcherWindow.close();
                            }
                        }
                    }
                }
            }

            // 應用程式列表
            ListView {
                id: appListView
                Layout.fillWidth: true
                height: Math.min(count * 46, 280)
                clip: true
                model: defaultAppsModel
                spacing: 4

                delegate: Rectangle {
                    width: appListView.width
                    height: 42
                    radius: Colors.cornerRadiusSmall
                    color: index === launcherWindow.selectedIndex ? Colors.lavender : (itemMouse.containsMouse ? Colors.glassCardHover : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        Text {
                            text: model.icon
                            font.pixelSize: 16
                        }

                        Column {
                            Layout.fillWidth: true
                            Text {
                                text: model.name
                                font.pixelSize: 13
                                font.bold: true
                                color: index === launcherWindow.selectedIndex ? Colors.crust : Colors.text
                            }
                            Text {
                                text: model.desc
                                font.pixelSize: 10
                                color: index === launcherWindow.selectedIndex ? Colors.surface0 : Colors.subtext
                            }
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.exec(["sh", "-c", model.exec]);
                            launcherWindow.close();
                        }
                    }
                }
            }
        }
    }
}
