import QtQuick
import Quickshell.Io

Item {
    id: niriService

    property var workspaces: [
        { "idx": 1, "is_focused": true },
        { "idx": 2, "is_focused": false },
        { "idx": 3, "is_focused": false }
    ]
    property string activeWindowTitle: ""
    property string activeAppId: ""

    function switchWorkspace(idx) {
        switchWsProc.command = ["niri", "msg", "action", "focus-workspace", idx.toString()]
        switchWsProc.running = true
    }

    Process {
        id: switchWsProc
    }

    Process {
        id: niriMonitor
        command: ["bash", "-c", "
            export LC_ALL=C
            update() {
                ws=$(niri msg -j workspaces 2>/dev/null || echo '[]')
                windows=$(niri msg -j windows 2>/dev/null || echo '[]')
                echo \"WS:$ws\"
                echo \"WIN:$windows\"
            }
            update
            niri msg -q event-stream 2>/dev/null | while read -r line; do
                update
            done
        "]
        running: true
        stdout: SplitParser {
            onRead: data => {
                var line = data
                if (line.startsWith("WS:")) {
                    try {
                        var parsed = JSON.parse(line.substring(3))
                        if (Array.isArray(parsed) && parsed.length > 0) {
                            var wsList = []
                            for (var i = 0; i < parsed.length; i++) {
                                var item = parsed[i]
                                wsList.push({
                                    "idx": item.idx !== undefined ? item.idx : (i + 1),
                                    "is_focused": item.is_focused || item.is_active || false,
                                    "id": item.id
                                })
                            }
                            // 按 idx 排序
                            wsList.sort((a, b) => a.idx - b.idx)
                            niriService.workspaces = wsList
                        }
                    } catch(e) {}
                } else if (line.startsWith("WIN:")) {
                    try {
                        var wins = JSON.parse(line.substring(4))
                        if (Array.isArray(wins)) {
                            var focused = wins.find(w => w.is_focused)
                            if (focused) {
                                niriService.activeWindowTitle = focused.title || focused.app_id || ""
                                niriService.activeAppId = focused.app_id || ""
                            } else {
                                niriService.activeWindowTitle = ""
                                niriService.activeAppId = ""
                            }
                        }
                    } catch(e) {}
                }
            }
        }
    }
}
