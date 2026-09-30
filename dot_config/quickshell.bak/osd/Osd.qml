import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: osdWindow

    property bool isShown: false
    property string iconText: "🔊"
    property string labelText: "音量"
    property int percentage: 50

    anchors {
        top: true
    }

    margins.top: 60
    width: 240
    height: 64
    color: "transparent"

    visible: isShown

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Timer {
        id: hideTimer
        interval: 1800
        repeat: false
        onTriggered: osdWindow.isShown = false
    }

    function showOsd(icon, label, value) {
        iconText = icon;
        labelText = label;
        percentage = Math.max(0, Math.min(100, value));
        isShown = true;
        hideTimer.restart();
    }

    Rectangle {
        id: osdCard
        anchors.fill: parent
        radius: Colors.cornerRadius
        color: Colors.glassBackground
        border.color: Colors.glassBorder
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: osdWindow.iconText
                    font.pixelSize: 14
                }
                Text {
                    text: osdWindow.labelText
                    font.pixelSize: 12
                    font.bold: true
                    color: Colors.text
                    Layout.fillWidth: true
                }
                Text {
                    text: osdWindow.percentage + "%"
                    font.pixelSize: 12
                    color: Colors.subtext
                }
            }

            // 進度條
            Rectangle {
                Layout.fillWidth: true
                height: 6
                radius: 3
                color: Colors.surface0

                Rectangle {
                    width: parent.width * (osdWindow.percentage / 100.0)
                    height: parent.height
                    radius: 3
                    color: Colors.lavender

                    Behavior on width {
                        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                    }
                }
            }
        }
    }
}
