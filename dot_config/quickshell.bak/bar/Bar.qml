import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.SystemTray
import "../theme"

PanelWindow {
    id: barWindow

    // 訊號與控制
    signal toggleControlCenter()
    signal openLauncher()

    anchors {
        top: true
        left: true
        right: true
    }

    height: 44
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // 週期定時器 (時鐘與系統狀態)
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            currentTime = Qt.formatDateTime(new Date(), "hh:mm");
            currentDate = Qt.formatDateTime(new Date(), "M月d日 ddd");
        }
    }

    property string currentTime: Qt.formatDateTime(new Date(), "hh:mm")
    property string currentDate: Qt.formatDateTime(new Date(), "M月d日 ddd")

    property int memPercent: 35
    property int batteryPercent: 85
    property bool isCharging: false
    property string activeWindowTitle: "Ready"

    // Waybar替代功能狀態
    property bool volMute: false
    property int volPct: 0
    property string wifiName: "Disconnected"
    property var wsData: []

    function parseWs(list) {
        if (!Array.isArray(list)) return
        var a = []
        for (var i = 0; i < list.length; i++) {
            var w = list[i]
            a.push({ idx: w.idx !== undefined ? w.idx : i+1,
                     focused: !!w.is_focused,
                     occupied: w.active_window_id != null })
        }
        a.sort(function(x, y) { return x.idx - y.idx })
        barWindow.wsData = a
    }

    // 讀取記憶體狀態
    Process {
        id: memProcess
        command: ["sh", "-c", "free | awk '/Mem:/ {printf(\"%.0f\", $3/$2 * 100)}'"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let val = parseInt(data.trim());
                if (!isNaN(val)) barWindow.memPercent = val;
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: memProcess.running = true
    }

    // 讀取筆電電池狀態 (Dell Latitude 7420)
    Process {
        id: batProcess
        command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1; cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1"]
        running: true
        stdout: SplitParser {
            property int lineCount: 0
            onRead: data => {
                let trimmed = data.trim();
                if (lineCount === 0) {
                    let val = parseInt(trimmed);
                    if (!isNaN(val)) barWindow.batteryPercent = val;
                    lineCount++;
                } else {
                    barWindow.isCharging = (trimmed === "Charging");
                    lineCount = 0;
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: batProcess.running = true
    }

    // 讀取音量 (Pipewire/Wireplumber)
    Process {
        id: volProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_SINK@"]
        stdout: SplitParser {
            onRead: data => {
                if (!data) return
                barWindow.volMute = data.indexOf("MUTED") !== -1
                var m = data.match(/([\d.]+)/)
                if (m) barWindow.volPct = Math.round(parseFloat(m[1]) * 100)
            }
        }
        Component.onCompleted: running = true
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: volProc.running = true }

    // 讀取 Wi-Fi 狀態
    Process {
        id: wifiProc
        command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi | awk -F: '/^yes/ {print $2}'"]
        stdout: SplitParser {
            onRead: data => { barWindow.wifiName = data.trim() || "Disconnected" }
        }
        Component.onCompleted: running = true
    }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: wifiProc.running = true }

    // 讀取 Niri 工作區 (事件流)
    Process {
        id: wsStream
        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try {
                    var e = JSON.parse(data)
                    if (e.WorkspacesChanged)       barWindow.parseWs(e.WorkspacesChanged.workspaces)
                    else if (e.WorkspaceActivated) wsQuery.running = true
                } catch(_) {}
            }
        }
        onRunningChanged: if (!running) wsRestart.start()
    }
    Timer { id: wsRestart; interval: 1500; onTriggered: wsStream.running = true }

    // 初始讀取 Niri 工作區
    Process {
        id: wsQuery
        command: ["niri", "msg", "--json", "workspaces"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    var p = JSON.parse(data)
                    var list = (p.Ok && p.Ok.Workspaces) ? p.Ok.Workspaces
                             : Array.isArray(p) ? p
                             : (p.Ok && Array.isArray(p.Ok)) ? p.Ok : null
                    if (list) barWindow.parseWs(list)
                } catch(_) {}
            }
        }
        Component.onCompleted: running = true
    }

    // 頂部懸浮島容器
    Item {
        anchors.fill: parent
        anchors.topMargin: 6
        anchors.leftMargin: 12
        anchors.rightMargin: 12

        // =========================================================
        // 左側島：開始功能表、工作區膠囊與視窗標題
        // =========================================================
        Rectangle {
            id: leftIsland
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: leftRow.implicitWidth + 24
            radius: Colors.cornerRadius
            color: Colors.glassBackground
            border.color: Colors.glassBorder
            border.width: 1

            RowLayout {
                id: leftRow
                anchors.centerIn: parent
                spacing: 10

                // 啟動器按鈕 (Windows Start 標誌)
                Rectangle {
                    width: 26
                    height: 26
                    radius: Colors.cornerRadiusSmall
                    color: startMouse.containsMouse ? Colors.glassCardHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "❖"
                        font.pixelSize: 15
                        color: Colors.lavender
                    }

                    MouseArea {
                        id: startMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: barWindow.openLauncher()
                    }
                }

                // 工作區膠囊指示點
                Row {
                    spacing: 5
                    Repeater {
                        model: barWindow.wsData
                        Rectangle {
                            width: modelData.focused ? 18 : 8
                            height: 8
                            radius: 4
                            color: modelData.focused ? Colors.lavender : (modelData.occupied ? Colors.text : Colors.surface1)
                            Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }
                }
            }
        }

        // =========================================================
        // 中央島：時鐘與日曆
        // =========================================================
        Rectangle {
            id: centerIsland
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: centerRow.implicitWidth + 28
            radius: Colors.cornerRadius
            color: Colors.glassBackground
            border.color: Colors.glassBorder
            border.width: 1

            RowLayout {
                id: centerRow
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: barWindow.currentTime
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: Colors.text
                }

                Rectangle {
                    width: 4
                    height: 4
                    radius: 2
                    color: Colors.lavender
                }

                Text {
                    text: barWindow.currentDate
                    font.pixelSize: 12
                    color: Colors.subtext
                }
            }
        }

        // =========================================================
        // 右側島：8GB RAM 監視、電池、Wi-Fi 與控制中心觸發
        // =========================================================
        Rectangle {
            id: rightIsland
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: rightRow.implicitWidth + 20
            radius: Colors.cornerRadius
            color: Colors.glassBackground
            border.color: Colors.glassBorder
            border.width: 1

            RowLayout {
                id: rightRow
                anchors.centerIn: parent
                spacing: 12

                // 8GB RAM 膠囊警告
                Row {
                    spacing: 4
                    Text {
                        text: "RAM"
                        font.pixelSize: 10
                        font.bold: true
                        color: barWindow.memPercent > 85 ? Colors.red : Colors.subtext
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: barWindow.memPercent + "%"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: barWindow.memPercent > 85 ? Colors.red : Colors.text
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    width: 1
                    height: 14
                    color: Colors.surface1
                }

                // 筆電電池電量 (含充電圖示)
                Row {
                    spacing: 4
                    Text {
                        text: barWindow.isCharging ? "⚡" : "🔋"
                        font.pixelSize: 12
                        color: barWindow.isCharging ? Colors.yellow : Colors.green
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: barWindow.batteryPercent + "%"
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Colors.text
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    width: 1
                    height: 14
                    color: Colors.surface1
                }

                // 音量
                Row {
                    spacing: 4
                    Text {
                        text: barWindow.volMute ? "🔇" : "🔊"
                        font.pixelSize: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: barWindow.volMute ? "Muted" : (barWindow.volPct + "%")
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Colors.text
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    width: 1
                    height: 14
                    color: Colors.surface1
                }

                // 網路 Wi-Fi
                Row {
                    spacing: 4
                    Text {
                        text: "📶"
                        font.pixelSize: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: barWindow.wifiName
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Colors.text
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    width: 1
                    height: 14
                    color: Colors.surface1
                }

                // 控制中心按鈕
                Rectangle {
                    width: 26
                    height: 26
                    radius: Colors.cornerRadiusSmall
                    color: ccMouse.containsMouse ? Colors.glassCardHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "⚙"
                        font.pixelSize: 14
                        color: Colors.lavender
                    }

                    MouseArea {
                        id: ccMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: barWindow.toggleControlCenter()
                    }
                }

                Rectangle {
                    width: 1
                    height: 14
                    color: Colors.surface1
                }

                // 系統匣 (System Tray)
                Row {
                    spacing: 8
                    Repeater {
                        model: SystemTray.items
                        Item {
                            width: 16
                            height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            Image {
                                anchors.fill: parent
                                source: modelData.icon
                                fillMode: Image.PreserveAspectFit
                            }
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.LeftButton) modelData.activate()
                                    else if (mouse.button === Qt.RightButton) modelData.contextMenu()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
