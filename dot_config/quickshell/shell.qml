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
        color: "#2B2B2B" // Dark grey background

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        // --- Data Properties ---
        property string clockText: "00:00"
        property string cpuText: "0%"
        property string memText: "0%"
        property string tempText: "0°C"
        property string batText: "100%"
        property string wifiText: "Not Connected"
        property string volText: "100%"

        // --- Hardware Fetcher ---
        Process {
            id: hwMonitor
            command: ["bash", "-c", "
                while true; do
                    # Mem
                    mem=$(free -m | awk '/Mem:/ {printf \"%d\", $3/$2 * 100.0}')
                    
                    # Temp
                    temp=$(sensors 2>/dev/null | grep -m1 -E 'Tctl|Package id 0|Core 0|temp1' | awk '{print $2}' | tr -d '+')
                    [ -z \"$temp\" ] && temp=\"N/A\"
                    
                    # Battery
                    bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1)
                    [ -z \"$bat\" ] && bat=\"100\"
                    
                    # Wifi
                    wifi=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2 | head -n1)
                    [ -z \"$wifi\" ] && wifi=\"Disconnected\"

                    # CPU
                    read -r cpu a b c previdle rest < /proc/stat
                    prevtotal=$((a+b+c+previdle))
                    sleep 0.5
                    read -r cpu a b c idle rest < /proc/stat
                    total=$((a+b+c+idle))
                    cpuload=$((100 * ( (total-prevtotal) - (idle-previdle) ) / (total-prevtotal) ))

                    echo \"MEM:${mem}%\"
                    echo \"TMP:${temp}\"
                    echo \"BAT:${bat}%\"
                    echo \"WIF:${wifi}\"
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
                    else if (line.startsWith("BAT:")) bar.batText = line.substring(4)
                    else if (line.startsWith("WIF:")) bar.wifiText = line.substring(4)
                    else if (line.startsWith("CPU:")) bar.cpuText = line.substring(4)
                }
            }
        }

        // --- Clock Fetcher ---
        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                bar.clockText = Qt.formatDateTime(new Date(), "hh:mm")
            }
        }

        // --- UI Layout ---
        Item {
            anchors.fill: parent
            
            // Left side (Empty or Workspaces)
            RowLayout {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: 0
            }

            // Right side
            Row {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: 0

                // 2. Wifi (Blue)
                Rectangle {
                    color: "#2980b9"
                    width: wifiLabel.width + 30
                    height: parent.height
                    Row {
                        anchors.centerIn: parent
                        spacing: 8
                        Text { text: ""; font.family: "JetBrainsMono Nerd Font"; color: "white"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                        Text { id: wifiLabel; text: bar.wifiText; color: "white"; font.family: "sans-serif"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                    }
                }

                // 3. Power Profile / Leaf (Green)
                Rectangle {
                    color: "#27ae60"
                    width: 35
                    height: parent.height
                    Text { text: ""; font.family: "JetBrainsMono Nerd Font"; color: "white"; font.pixelSize: 14; anchors.centerIn: parent }
                }

                // 4. CPU (Green/Teal)
                Rectangle {
                    color: "#16a085"
                    width: cpuLabel.width + 30
                    height: parent.height
                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: ""; font.family: "JetBrainsMono Nerd Font"; color: "white"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                        Text { id: cpuLabel; text: bar.cpuText; color: "white"; font.family: "sans-serif"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                    }
                }

                // 5. Memory (Purple)
                Rectangle {
                    color: "#8e44ad"
                    width: memLabel.width + 30
                    height: parent.height
                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: ""; font.family: "JetBrainsMono Nerd Font"; color: "white"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                        Text { id: memLabel; text: bar.memText; color: "white"; font.family: "sans-serif"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                    }
                }

                // 6. Temp (Orange)
                Rectangle {
                    color: "#d35400"
                    width: tempLabel.width + 30
                    height: parent.height
                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: ""; font.family: "JetBrainsMono Nerd Font"; color: "white"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                        Text { id: tempLabel; text: bar.tempText; color: "white"; font.family: "sans-serif"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                    }
                }

                // 7. Disk (Grey)
                Rectangle {
                    color: "#7f8c8d"
                    width: 60
                    height: parent.height
                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: ""; font.family: "JetBrainsMono Nerd Font"; color: "white"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "26%"; color: "white"; font.family: "sans-serif"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                    }
                }

                // 8. Battery (White)
                Rectangle {
                    color: "#ecf0f1"
                    width: batLabel.width + 30
                    height: parent.height
                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: ""; font.family: "JetBrainsMono Nerd Font"; color: "#2c3e50"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                        Text { id: batLabel; text: bar.batText; color: "#2c3e50"; font.family: "sans-serif"; font.pixelSize: 13; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                    }
                }

                // 9. Clock (Grey/Blue)
                Rectangle {
                    color: "#34495e"
                    width: clockLabel.width + 30
                    height: parent.height
                    Text { id: clockLabel; text: bar.clockText; color: "white"; font.family: "sans-serif"; font.bold: true; font.pixelSize: 13; anchors.centerIn: parent }
                }

                // 10. Input (Blue)
                Rectangle {
                    color: "#2980b9"
                    width: 40
                    height: parent.height
                    Text { text: ""; font.family: "JetBrainsMono Nerd Font"; color: "white"; font.pixelSize: 16; anchors.centerIn: parent }
                }
            }
        }
    }
}
