import QtQuick
import Quickshell
import "theme"
import "bar"
import "controlcenter"
import "osd"
import "launcher"
import "notifications"

ShellRoot {
    id: root

    // 1. 頂部懸浮島式狀態列
    Bar {
        id: bar
        onToggleControlCenter: {
            controlCenter.isOpen = !controlCenter.isOpen;
        }
        onOpenLauncher: {
            spotlightLauncher.toggle();
        }
    }

    // 2. 抽屜式控制中心
    ControlCenter {
        id: controlCenter
    }

    // 3. 浮動音量與亮度 OSD
    Osd {
        id: osd
    }

    // 4. Spotlight 式居中啟動器
    SpotlightLauncher {
        id: spotlightLauncher
    }

    // 5. 桌面毛玻璃通知彈窗
    NotificationPopup {
        id: notifPopup
    }

    // 支援 IPC 呼叫切換啟動器或控制中心 (供 Niri 快捷鍵使用)
    IpcHandler {
        target: "launcher"
        onMessage: {
            spotlightLauncher.toggle();
        }
    }

    IpcHandler {
        target: "controlcenter"
        onMessage: {
            controlCenter.isOpen = !controlCenter.isOpen;
        }
    }
}
