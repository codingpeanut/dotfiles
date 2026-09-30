pragma Singleton
import QtQuick

QtObject {
    id: root

    // 預設為深色模式 (Catppuccin Mocha)
    property bool isDarkMode: true

    function toggleTheme() {
        isDarkMode = !isDarkMode;
    }

    function setDarkMode(enabled) {
        isDarkMode = enabled;
    }
}
