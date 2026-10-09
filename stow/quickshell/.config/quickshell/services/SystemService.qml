import QtQuick
import Quickshell.Io

Item {
    id: systemService

    // 時間與日期 (截圖同款格式: 06:22 AM | Sun, 30-Mar)
    property string timeString: "06:22 AM"
    property string dateString: "Sun, 30-Mar"

    // 音量 (耳機/喇叭圖示 󰋋)
    property string volumeText: "39%"
    property string volumeIcon: "󰋋"

    // 電量 (充飽/放電圖示 󰂄)
    property string batteryText: "100%"
    property string batteryIcon: "󰂄"

    // 網路 (Wi-Fi 滿格圖示 󰤨)
    property string wifiIcon: "󰤨"
    property string wifiSsid: "Connected"

    // 硬體狀態 (晶片/記憶體圖示 󱄅)
    property string cpuUsage: "12%"

    // 通知計數 (截圖同款: 󰂚 38)
    property int notificationCount: 0

    // 天氣資訊 (截圖同款: 󰖙 Sunny, -14°C)
    property string weatherText: "Sunny, 24°C"
    property string weatherIcon: "󰖙"

    // 每秒更新時鐘
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date()
            var hours = now.getHours()
            var ampm = hours >= 12 ? "PM" : "AM"
            hours = hours % 12
            hours = hours ? (hours < 10 ? "0" + hours : hours) : "12"
            var minutes = now.getMinutes() < 10 ? "0" + now.getMinutes() : now.getMinutes()

            var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            var dayName = days[now.getDay()]
            var monthName = months[now.getMonth()]
            var dateNum = now.getDate()

            systemService.timeString = hours + ":" + minutes + " " + ampm
            systemService.dateString = dayName + ", " + dateNum + "-" + monthName
        }
    }

    // 定期抓取音量、電量、網路與硬體負載
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            sysStatsProc.running = true
        }
    }

    Process {
        id: sysStatsProc
        command: ["bash", "-c", "
            # 音量
            vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -Po '\\d+(?=%)' | head -n 1 || echo \"50\")
            mute=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | grep -o 'yes' || echo 'no')
            
            # 電量
            bat=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n 1 || echo \"100\")
            status=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n 1 || echo \"Full\")

            # 網路
            wifi=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2 || echo \"LAN\")

            # CPU
            cpu=$(top -bn1 2>/dev/null | grep 'Cpu(s)' | awk '{print int(100 - $8)}' || echo '5')

            # 通知計數 (可選取 mako/fuzzel/cliphist 概況)
            notifs=$(cat ~/.cache/notification_count 2>/dev/null || echo '0')

            echo \"SYS:$vol:$mute:$bat:$status:$wifi:$cpu:$notifs\"
        "]
        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("SYS:")) {
                    var parts = data.substring(4).split(":")
                    var vol = parts[0] || "50"
                    var isMute = parts[1] === "yes"
                    var bat = parts[2] || "100"
                    var batStatus = parts[3] || "Full"
                    var wifi = parts[4] || ""
                    var cpu = parts[5] || "5"
                    var notifs = parseInt(parts[6] || "0")

                    systemService.volumeText = isMute ? "Muted" : (vol + "%")
                    systemService.volumeIcon = isMute ? "󰝟" : "󰋋"

                    systemService.batteryText = bat + "%"
                    systemService.batteryIcon = (batStatus === "Charging") ? "󰂄" : "󰁹"

                    systemService.wifiIcon = (wifi !== "") ? "󰤨" : "󰤭"
                    systemService.wifiSsid = wifi

                    systemService.cpuUsage = cpu + "%"
                    systemService.notificationCount = isNaN(notifs) ? 0 : notifs
                }
            }
        }
    }

    // 啟動時背景抓取一次天氣
    Process {
        id: weatherProc
        running: true
        command: ["bash", "-c", "
            w=$(curl -s --max-time 4 'wttr.in/?format=%c+%C,+%t' 2>/dev/null || echo '')
            if [ -n \"$w\" ]; then
                echo \"WEATHER:$w\"
            else
                echo \"WEATHER:󰖙 Sunny, 24°C\"
            fi
        "]
        stdout: SplitParser {
            onRead: data => {
                if (data.startsWith("WEATHER:")) {
                    var raw = data.substring(8).trim()
                    if (raw.length > 0) {
                        systemService.weatherText = raw
                    }
                }
            }
        }
    }
}
