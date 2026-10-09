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
    visible: opacity > 0.001
    opacity: isOpen ? 1.0 : 0.0

    // 全視窗平滑淡入淡出動畫
    Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

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

    // 完整的常用應用程式清單
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

    // 背景半透明暗色遮罩 (支援淡入)
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.52)

        MouseArea {
            anchors.fill: parent
            onClicked: launcherWindow.close()
        }
    }

    // 截圖同款居中雙欄 Rofi 主視窗 (720px x 420px，帶 Spring & Scale 彈動開合動效)
    Rectangle {
        id: mainDialog
        width: 720
        height: 420
        anchors.horizontalCenter: parent.horizontalCenter
        radius: Theme.radiusModal
        color: Theme.bgTranslucent
        border.width: 1
        border.color: Theme.borderColor
        clip: true

        // 高級 Spring 與 Scale 彈簧動效
        scale: launcherWindow.isOpen ? 1.0 : 0.93
        opacity: launcherWindow.isOpen ? 1.0 : 0.0
        y: launcherWindow.isOpen ? (parent.height - height) / 2 : ((parent.height - height) / 2 + 18)

        Behavior on scale {
            NumberAnimation { duration: 240; easing.type: Easing.OutBack; overshoot: 1.15 }
        }
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on y {
            NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
        }

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
                color: Qt.rgba(16/255, 14/255, 20/255, 0.70)

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

                    // 1. 頂部搜尋列 ( Search... 帶微發光焦點動效)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: Theme.radiusItem + 2
                        color: searchField.activeFocus ? Qt.rgba(40/255, 36/255, 52/255, 0.95) : Qt.rgba(28/255, 24/255, 36/255, 0.8)
                        border.width: 1
                        border.color: searchField.activeFocus ? Theme.borderActiveColor : Theme.borderColor

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: ""
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                color: searchField.activeFocus ? Theme.accentPurple : Theme.textMuted
                                Behavior on color { ColorAnimation { duration: 150 } }
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

                        Rectangle {
                            anchors.centerIn: parent
                            width: 170
                            height: 104
                            radius: 14
                            color: Qt.rgba(255, 255, 255, 0.02)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.05)

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "󰌽"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 32
                                    color: Qt.rgba(208/255, 188/255, 255/255, 0.35)
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Niri • Desktop Shell"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                }
                            }
                        }
                    }

                    // 3. 底部模式標籤列 [ APPS ]  RUN  FILES  WINDOW (帶流體滑動滑塊 Fluid Glider)
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28

                        // 共享的薄荷綠流體滑動卡片 (Fluid Sliding Pill)
                        Rectangle {
                            id: tabGlider
                            height: 26
                            radius: Theme.radiusItem
                            color: Theme.accentMint
                            anchors.verticalCenter: parent.verticalCenter

                            // 追蹤當前 activeMode 標籤的幾何位置
                            x: currentActiveTab ? currentActiveTab.x : 0
                            width: currentActiveTab ? currentActiveTab.width : 56

                            Behavior on x {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                            Behavior on width {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }
                        }

                        RowLayout {
                            id: tabsRow
                            anchors.fill: parent
                            spacing: 6

                            // APPS
                            Item {
                                id: tabApps
                                implicitWidth: 58
                                implicitHeight: 26

                                Text {
                                    anchors.centerIn: parent
                                    text: "APPS"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: launcherWindow.activeMode === "APPS" ? Theme.textDark : (appsMouse.containsMouse ? Theme.textPrimary : Theme.textMuted)
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    id: appsMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: launcherWindow.activeMode = "APPS"
                                }
                            }

                            // RUN
                            Item {
                                id: tabRun
                                implicitWidth: 46
                                implicitHeight: 26

                                Text {
                                    anchors.centerIn: parent
                                    text: "RUN"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: launcherWindow.activeMode === "RUN" ? Theme.textDark : (runMouse.containsMouse ? Theme.textPrimary : Theme.textMuted)
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    id: runMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: launcherWindow.activeMode = "RUN"
                                }
                            }

                            // FILES
                            Item {
                                id: tabFiles
                                implicitWidth: 52
                                implicitHeight: 26

                                Text {
                                    anchors.centerIn: parent
                                    text: "FILES"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: launcherWindow.activeMode === "FILES" ? Theme.textDark : (filesMouse.containsMouse ? Theme.textPrimary : Theme.textMuted)
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    id: filesMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: launcherWindow.activeMode = "FILES"
                                }
                            }

                            // WINDOW
                            Item {
                                id: tabWindow
                                implicitWidth: 62
                                implicitHeight: 26

                                Text {
                                    anchors.centerIn: parent
                                    text: "WINDOW"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: launcherWindow.activeMode === "WINDOW" ? Theme.textDark : (winMouse.containsMouse ? Theme.textPrimary : Theme.textMuted)
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    id: winMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: launcherWindow.activeMode = "WINDOW"
                                }
                            }
                        }

                        property var currentActiveTab: {
                            if (launcherWindow.activeMode === "APPS") return tabApps
                            if (launcherWindow.activeMode === "RUN") return tabRun
                            if (launcherWindow.activeMode === "FILES") return tabFiles
                            return tabWindow
                        }
                    }
                }
            }

            // =================================================================
            // 右欄 (純淨深色應用清單，帶流暢滑動光標 Smooth Highlight Follower)
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
                    currentIndex: launcherWindow.selectedIndex

                    // 垂直滑動的高光光標卡片 (Raycast/macOS 級流暢追隨)
                    highlight: Rectangle {
                        radius: Theme.radiusItem + 2
                        color: Theme.bgSelected
                        border.width: 1
                        border.color: Theme.borderActiveColor
                        z: 1
                    }
                    highlightFollowsCurrentItem: true
                    highlightMoveDuration: 140

                    delegate: Item {
                        id: appItem
                        width: appsListView.width
                        height: 38
                        z: 2

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
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }

                            // 應用名稱 + 括號副標題 (Firefox (web browser))
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    text: model.name
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.bold: index === launcherWindow.selectedIndex
                                    color: Theme.textPrimary
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
                            onPositionChanged: {
                                launcherWindow.selectedIndex = index
                            }
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
