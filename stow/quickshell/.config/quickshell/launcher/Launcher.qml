import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"

PanelWindow {
    id: launcherWindow

    property bool isOpen: false
    property int selectedIndex: 0
    property string activeMode: "APPS" // APPS, RUN, FILES, WINDOW

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
        isOpen = !isOpen
        if (isOpen) {
            searchField.text = ""
            searchField.forceActiveFocus()
            selectedIndex = 0
            filterApps("")
        }
    }

    function close() {
        isOpen = false
    }

    function launchSelected() {
        if (filteredModel.count > 0 && selectedIndex >= 0 && selectedIndex < filteredModel.count) {
            var item = filteredModel.get(selectedIndex)
            execProc.command = ["bash", "-c", item.exec + " &"]
            execProc.running = true
            close()
        }
    }

    Process {
        id: execProc
    }

    // 完整的預設常用與已安裝工具清單 (精確還原截圖與常用應用)
    ListModel {
        id: rawAppsModel
        ListElement { name: "Lutris"; subtitle: ""; icon: "󰊴"; exec: "lutris" }
        ListElement { name: "Firefox"; subtitle: "(web browser)"; icon: "󰈹"; exec: "firefox" }
        ListElement { name: "Brave"; subtitle: "(web browser)"; icon: "󰖟"; exec: "brave" }
        ListElement { name: "Google Chrome"; subtitle: "(web browser)"; icon: ""; exec: "google-chrome" }
        ListElement { name: "Mission Center"; subtitle: ""; icon: "󰓅"; exec: "missioncenter" }
        ListElement { name: "Free Download Manager"; subtitle: ""; icon: "󰇚"; exec: "fdm" }
        ListElement { name: "Waypaper"; subtitle: "(waypaper wallpaper setter)"; icon: ""; exec: "waypaper" }
        ListElement { name: "Winetricks"; subtitle: ""; icon: "󰡶"; exec: "winetricks" }
        ListElement { name: "Kitty Terminal"; subtitle: "(terminal)"; icon: "󰄛"; exec: "kitty" }
        ListElement { name: "Visual Studio Code"; subtitle: "(code editor)"; icon: "󰨞"; exec: "code" }
        ListElement { name: "Files (Nautilus)"; subtitle: "(file manager)"; icon: "󰉋"; exec: "nautilus" }
        ListElement { name: "Volume Control"; subtitle: "(pavucontrol)"; icon: "󰕾"; exec: "pavucontrol" }
        ListElement { name: "Process Monitor"; subtitle: "(btop)"; icon: "󱄅"; exec: "kitty -e btop" }
    }

    ListModel {
        id: filteredModel
    }

    function filterApps(query) {
        filteredModel.clear()
        var q = query.trim().toLowerCase()
        for (var i = 0; i < rawAppsModel.count; i++) {
            var item = rawAppsModel.get(i)
            if (q === "" || item.name.toLowerCase().includes(q) || item.subtitle.toLowerCase().includes(q)) {
                filteredModel.append(item)
            }
        }
        selectedIndex = 0
    }

    // 背景半透明暗色遮罩
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.50)

        MouseArea {
            anchors.fill: parent
            onClicked: launcherWindow.close()
        }
    }

    // 截圖同款居中雙欄 Rofi 主視窗 (720px x 420px)
    Rectangle {
        id: mainDialog
        width: 720
        height: 420
        anchors.centerIn: parent
        radius: Theme.radiusModal
        color: Theme.bgTranslucent
        border.width: 1
        border.color: Theme.borderColor
        clip: true

        // 鍵盤導航監聽
        Keys.onEscapePressed: launcherWindow.close()
        Keys.onReturnPressed: launcherWindow.launchSelected()
        Keys.onEnterPressed: launcherWindow.launchSelected()
        Keys.onDownPressed: {
            if (filteredModel.count > 0) {
                selectedIndex = (selectedIndex + 1) % filteredModel.count
                appsListView.positionViewAtIndex(selectedIndex, ListView.Contain)
            }
        }
        Keys.onUpPressed: {
            if (filteredModel.count > 0) {
                selectedIndex = (selectedIndex - 1 + filteredModel.count) % filteredModel.count
                appsListView.positionViewAtIndex(selectedIndex, ListView.Contain)
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // =================================================================
            // 左欄 (毛玻璃搜尋區 + 底部 APPS / RUN / FILES / WINDOW 標籤)
            // =================================================================
            Rectangle {
                Layout.preferredWidth: 290
                Layout.fillHeight: true
                color: Qt.rgba(16/255, 14/255, 20/255, 0.65)

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: Theme.borderColor
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    // 1. 頂部搜尋列 ( Search...)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: Theme.radiusItem + 2
                        color: Qt.rgba(32/255, 28/255, 40/255, 0.8)
                        border.width: 1
                        border.color: searchField.activeFocus ? Theme.borderActiveColor : Theme.borderColor

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: ""
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: Theme.textMuted
                            }

                            TextInput {
                                id: searchField
                                Layout.fillWidth: true
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: Theme.textPrimary
                                selectByMouse: true
                                verticalAlignment: TextInput.AlignVCenter

                                Text {
                                    text: "Search"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    color: Theme.textMuted
                                    visible: !searchField.text && !searchField.activeFocus
                                }

                                onTextChanged: {
                                    launcherWindow.filterApps(text)
                                }
                            }
                        }
                    }

                    // 2. 中央區域 (微透景深)
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        // 裝飾性低調微光卡片
                        Rectangle {
                            anchors.centerIn: parent
                            width: 160
                            height: 100
                            radius: 12
                            color: Qt.rgba(255, 255, 255, 0.02)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.05)

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "󰌽"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 28
                                    color: Qt.rgba(208/255, 188/255, 255/255, 0.25)
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Niri • Desktop"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                }
                            }
                        }
                    }

                    // 3. 底部模式標籤列 [ APPS ]  RUN  FILES  WINDOW
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // APPS (活躍項，截圖同款薄荷綠卡片)
                        Rectangle {
                            implicitWidth: 64
                            implicitHeight: 26
                            radius: Theme.radiusItem
                            color: launcherWindow.activeMode === "APPS" ? Theme.accentMint : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "APPS"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: true
                                color: launcherWindow.activeMode === "APPS" ? Theme.textDark : Theme.textMuted
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: launcherWindow.activeMode = "APPS"
                            }
                        }

                        // RUN
                        Rectangle {
                            implicitWidth: 44
                            implicitHeight: 26
                            radius: Theme.radiusItem
                            color: launcherWindow.activeMode === "RUN" ? Theme.accentMint : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "RUN"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: launcherWindow.activeMode === "RUN"
                                color: launcherWindow.activeMode === "RUN" ? Theme.textDark : Theme.textMuted
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: launcherWindow.activeMode = "RUN"
                            }
                        }

                        // FILES
                        Rectangle {
                            implicitWidth: 50
                            implicitHeight: 26
                            radius: Theme.radiusItem
                            color: launcherWindow.activeMode === "FILES" ? Theme.accentMint : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "FILES"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: launcherWindow.activeMode === "FILES"
                                color: launcherWindow.activeMode === "FILES" ? Theme.textDark : Theme.textMuted
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: launcherWindow.activeMode = "FILES"
                            }
                        }

                        // WINDOW
                        Rectangle {
                            implicitWidth: 60
                            implicitHeight: 26
                            radius: Theme.radiusItem
                            color: launcherWindow.activeMode === "WINDOW" ? Theme.accentMint : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: "WINDOW"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.bold: launcherWindow.activeMode === "WINDOW"
                                color: launcherWindow.activeMode === "WINDOW" ? Theme.textDark : Theme.textMuted
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: launcherWindow.activeMode = "WINDOW"
                            }
                        }
                    }
                }
            }

            // =================================================================
            // 右欄 (純淨深色應用清單)
            // =================================================================
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: appsListView
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 4
                    clip: true
                    model: filteredModel

                    delegate: Rectangle {
                        id: appItem
                        width: appsListView.width
                        height: 38
                        radius: Theme.radiusItem + 2

                        // 截圖同款選中高光深色小卡片
                        color: index === launcherWindow.selectedIndex ? Theme.bgSelected : (itemMouse.containsMouse ? Theme.bgCardHover : "transparent")
                        border.width: index === launcherWindow.selectedIndex ? 1 : 0
                        border.color: Theme.borderActiveColor

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            // 應用圖標
                            Text {
                                text: model.icon
                                font.family: Theme.fontFamily
                                font.pixelSize: 16
                                color: index === launcherWindow.selectedIndex ? Theme.accentPurple : Theme.textSecondary
                            }

                            // 應用名稱 + 括號副標題 (截圖同款: Firefox (web browser))
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    text: model.name
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: index === launcherWindow.selectedIndex
                                    color: index === launcherWindow.selectedIndex ? Theme.textPrimary : Theme.textPrimary
                                }

                                Text {
                                    text: model.subtitle
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    color: Theme.textMuted
                                    visible: model.subtitle !== ""
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                launcherWindow.selectedIndex = index
                                launcherWindow.launchSelected()
                            }
                        }
                    }
                }
            }
        }
    }
}
