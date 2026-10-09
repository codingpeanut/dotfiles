import QtQuick
import Quickshell.Io

Item {
    id: mprisService

    property string trackText: ""
    property bool isPlaying: false
    property string playerIcon: "" // 預設 Spotify 綠標

    function togglePlay() {
        actionProc.command = ["playerctl", "play-pause"]
        actionProc.running = true
    }

    Process {
        id: actionProc
    }

    Timer {
        interval: 2500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            pollProc.running = true
        }
    }

    Process {
        id: pollProc
        command: ["bash", "-c", "
            status=$(playerctl status 2>/dev/null || echo \"Stopped\")
            if [ \"$status\" = \"Playing\" ] || [ \"$status\" = \"Paused\" ]; then
                artist=$(playerctl metadata artist 2>/dev/null || echo \"\")
                title=$(playerctl metadata title 2>/dev/null || echo \"\")
                if [ -n \"$artist\" ] && [ -n \"$title\" ]; then
                    echo \"TRACK:$status:$artist - $title\"
                elif [ -n \"$title\" ]; then
                    echo \"TRACK:$status:$title\"
                else
                    echo \"TRACK:$status:Media Playing\"
                fi
            else
                echo \"TRACK:Stopped:\"
            fi
        "]
        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("TRACK:")) {
                    var rest = data.substring(6)
                    var firstColon = rest.indexOf(":")
                    if (firstColon !== -1) {
                        var status = rest.substring(0, firstColon)
                        var text = rest.substring(firstColon + 1).trim()
                        mprisService.isPlaying = (status === "Playing")
                        mprisService.trackText = text
                    }
                }
            }
        }
    }
}
