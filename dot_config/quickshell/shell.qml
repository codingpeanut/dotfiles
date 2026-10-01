import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

ShellRoot {
    PanelWindow {
        id: bar
        anchors {
            top: true
            left: true
            right: true
        }
        height: 30
        color: Qt.rgba(43/255, 48/255, 59/255, 0.5)

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 3
            color: Qt.rgba(100/255, 114/255, 125/255, 0.5)
        }

        property string clockText: "00:00"
        property string cpuText: "0%"
        property string memText: "0%"
        property string tempText: "0°C"
        property string batText: "100%"
        property string batIcon: ""
        property string wifiText: "Disconnected ⚠"
        property string volText: "100%"
        property string windowTitle: ""
        property var workspaces: []

        Process {
            id: niriMonitor
            command: ["bash", "-c", "
                export LC_ALL=C
                update() {
                    ws=$(niri msg -j workspaces 2>/dev/null)
                    windows=$(niri msg -j windows 2>/dev/null)
                    echo \"WS:$ws\"
                    echo \"WIN:$windows\"
                }
                update
                niri msg -q event-stream | while read -r line; do
                    update
                done
            "]
            running: true
            onStdout: (data) => {
                var lines = data.split('\n')
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i]
                    if (line.startsWith("WS:")) {
                        try {
                            bar.workspaces = JSON.parse(line.substring(3))
                        } catch(e) {}
                    } else if (line.startsWith("WIN:")) {
                        try {
                            var wins = JSON.parse(line.substring(4))
                            var activeFound = false
                            for (var j = 0; j < wins.length; j++) {
                                if (wins[j].is_focused) {
                                    bar.windowTitle = wins[j].title || ""
                                    activeFound = true
                                    break
                                }
                            }
                            if (!activeFound) bar.windowTitle = ""
                        } catch(e) {}
                    }
                }
            }
        }

        Process {
            id: hwMonitor
            command: ["bash", "-c", "
                export LC_ALL=C
                while true; do
                    mem=$(free -m | awk '/Mem:/ {printf \"%d\", $3/$2 * 100.0}')
                    
                    temp=$(sensors 2>/dev/null | grep -m1 -E 'Tctl|Package id 0|Core 0|temp1' | awk '{print $2}' | tr -d '+')
                    [ -z \"$temp\" ] && temp=\"N/A\"
                    
                    bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1)
                    [ -z \"$bat\" ] && bat=\"100\"
                    
                    wifi=$(nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2,3 | head -n1)
                    if [ -z \"$wifi\" ]; then
                        echo \"WIF:Disconnected ⚠\"
                    else
                        ssid=$(echo \"$wifi\" | cut -d: -f1)
                        sig=$(echo \"$wifi\" | cut -d: -f2)
                        echo \"WIF:$ssid ($sig%) \"
                    fi

                    vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print int($2 * 100)}')
                    echo \"VOL:${vol}%\"

                    read -r cpu a b c previdle rest < /proc/stat
                    prevtotal=$((a+b+c+previdle))
                    sleep 0.5
                    read -r cpu a b c idle rest < /proc/stat
                    total=$((a+b+c+idle))
                    cpuload=$((100 * ( (total-prevtotal) - (idle-previdle) ) / (total-prevtotal) ))

                    echo \"MEM:${mem}%\"
                    echo \"TMP:${temp}\"
                    echo \"BAT:${bat}\"
                    echo \"CPU:${cpuload}%\"
                    
                    sleep 1.5
                done
            "]
            running: true
            onStdout: (data) => {
                var lines = data.split('\n')
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i]
                    if (line.startsWith("MEM:")) bar.memText = line.substring(4)
                    else if (line.startsWith("TMP:")) bar.tempText = line.substring(4)
                    else if (line.startsWith("BAT:")) {
                        var cap = parseInt(line.substring(4))
                        bar.batText = cap + "%"
                        if (cap > 90) bar.batIcon = ""
                        else if (cap > 70) bar.batIcon = ""
                        else if (cap > 40) bar.batIcon = ""
                        else if (cap > 15) bar.batIcon = ""
                        else bar.batIcon = ""
                    }
                    else if (line.startsWith("WIF:")) bar.wifiText = line.substring(4)
                    else if (line.startsWith("CPU:")) bar.cpuText = line.substring(4)
                    else if (line.startsWith("VOL:")) bar.volText = line.substring(4)
                }
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                bar.clockText = Qt.formatDateTime(new Date(), "yyyy-MM-dd hh:mm")
            }
        }

        component Module: Rectangle {
            property alias text: label.text
            property alias textColor: label.color
            color: "transparent"
            height: 30
            width: label.width + 20
            Text {
                id: label
                anchors.centerIn: parent
                font.family: "Noto Sans Mono, JetBrainsMono Nerd Font"
                font.pixelSize: 13
                color: "#ffffff"
            }
        }

        Item {
            anchors.fill: parent
            
            Row {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: 4
                
                Repeater {
                    model: bar.workspaces
                    Rectangle {
                        height: 30
                        width: wsText.width + 10
                        color: modelData.is_focused ? "#64727D" : "transparent"
                        
                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 3
                            color: modelData.is_focused ? "#ffffff" : "transparent"
                        }
                        
                        Text {
                            id: wsText
                            text: modelData.name ? modelData.name : modelData.id
                            color: "#ffffff"
                            font.family: "Noto Sans Mono, JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                var proc = Qt.createQmlObject('import Quickshell.Io; Process { command: ["niri", "msg", "action", "focus-workspace", "'+modelData.id+'"]; running: true }', bar)
                            }
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: bar.windowTitle
                color: "#ffffff"
                font.family: "Noto Sans Mono, JetBrainsMono Nerd Font"
                font.pixelSize: 13
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 400)
            }

            Row {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: 4

                Module {
                    color: "#2d3436"
                    text: ""
                }
                
                Module {
                    color: "#f1c40f"
                    textColor: "#000000"
                    text: bar.volText + " "
                }

                Module {
                    color: "#2980b9"
                    text: bar.wifiText
                }

                Module {
                    color: "#2980b9"
                    text: ""
                }

                Module {
                    color: "#2ecc71"
                    textColor: "#000000"
                    text: bar.cpuText + " "
                }

                Module {
                    color: "#9b59b6"
                    text: bar.memText + " "
                }

                Module {
                    color: "#f0932b"
                    text: bar.tempText + " "
                }

                Module {
                    color: "#ffffff"
                    textColor: "#000000"
                    text: bar.batText + " " + bar.batIcon
                }

                Module {
                    color: "#64727D"
                    text: bar.clockText
                }
            }
        }
    }
}
