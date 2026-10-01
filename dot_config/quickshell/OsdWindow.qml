import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

PanelWindow {
    id: osd
    anchors {
        bottom: true
    }
    margins.bottom: 100
    width: 250
    height: 50
    color: "transparent"
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property int volume: 50
    property string volumeIcon: ""

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: content.opacity = 0
    }

    Process {
        command: ["bash", "-c", "
            export LC_ALL=C
            pactl subscribe | grep --line-buffered \"change\" | while read -r line; do
                vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')
                echo \"$vol\"
            done
        "]
        running: true
        stdout: SplitParser {
            onRead: data => {
                if (data.trim().length > 0) {
                    var vol = parseInt(data.trim())
                    if (!isNaN(vol)) {
                        osd.volume = vol
                        if (vol > 60) osd.volumeIcon = ""
                        else if (vol > 30) osd.volumeIcon = ""
                        else if (vol > 0) osd.volumeIcon = ""
                        else osd.volumeIcon = ""
                        
                        content.opacity = 1
                        hideTimer.restart()
                    }
                }
            }
        }
    }

    Rectangle {
        id: content
        anchors.fill: parent
        color: Qt.rgba(43/255, 48/255, 59/255, 0.9)
        opacity: 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 3
            color: Qt.rgba(100/255, 114/255, 125/255, 0.5)
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 15
            anchors.rightMargin: 15
            spacing: 15

            Text {
                text: osd.volumeIcon
                color: "#f1c40f"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                anchors.verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: 170
                height: 10
                color: "#1e2229"
                radius: 5
                anchors.verticalCenter: parent.verticalCenter
                
                Rectangle {
                    width: Math.min(parent.width, parent.width * (osd.volume / 100))
                    height: parent.height
                    color: "#f1c40f"
                    radius: 5
                }
            }
        }
    }
}
