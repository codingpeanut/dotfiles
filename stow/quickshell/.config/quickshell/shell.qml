import QtQuick
import Quickshell
import Quickshell.Io
import "theme"
import "services"
import "bar"
import "launcher"

ShellRoot {
    id: root

    // 全域服務層 (單一實例共享資料)
    NiriService {
        id: niriService
    }

    MprisService {
        id: mprisService
    }

    SystemService {
        id: systemService
    }

    // 1. 頂部懸浮島式狀態列 (Modular Island Bar)
    Bar {
        id: bar
        niriService: niriService
        mprisService: mprisService
        systemService: systemService

        onOpenLauncher: {
            launcher.toggle()
        }

        onOpenPowerMenu: {
            powerProc.command = ["bash", "-c", "command -v wlogout >/dev/null 2>&1 && wlogout || power-menu"]
            powerProc.running = true
        }
    }

    Process {
        id: powerProc
    }

    // 2. 雙欄式毛玻璃啟動器 (Dual-Pane Frosted Launcher)
    Launcher {
        id: launcher
    }

    // 支援 IPC 呼叫切換啟動器 (供 Niri 快捷鍵 Mod+Space 或 Mod+D 呼叫)
    IpcHandler {
        target: "launcher"
        function toggle(): void {
            launcher.toggle()
        }
        function open(): void {
            if (!launcher.isOpen) launcher.toggle()
        }
        function close(): void {
            launcher.close()
        }
    }
}
