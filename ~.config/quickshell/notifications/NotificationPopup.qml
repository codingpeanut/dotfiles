import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: notifWindow

    anchors {
        top: true
        right: true
    }

    margins {
        top: 50
        right: 14
    }

    width: 320
    height: notifCol.implicitHeight + 10
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // 模擬或對接桌面通知模型
    ListModel {
        id: notifList
    }

    function addNotification(app, title, body) {
        notifList.append({
            app: app,
            title: title,
            body: body,
            time: Qt.formatDateTime(new Date(), "hh:mm")
        });
    }

    ColumnLayout {
        id: notifCol
        width: parent.width
        spacing: 8

        Repeater {
            model: notifList

            delegate: Rectangle {
                Layout.fillWidth: true
                height: 72
                radius: Colors.cornerRadius
                color: Colors.glassBackground
                border.color: Colors.glassBorder
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: model.app || "系統通知"
                            font.pixelSize: 11
                            font.bold: true
                            color: Colors.lavender
                            Layout.fillWidth: true
                        }
                        Text {
                            text: model.time
                            font.pixelSize: 10
                            color: Colors.overlay
                        }
                    }

                    Text {
                        text: model.title
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: Colors.text
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: model.body
                        font.pixelSize: 11
                        color: Colors.subtext
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: notifList.remove(index)
                }
            }
        }
    }
}
