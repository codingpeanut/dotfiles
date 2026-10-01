import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

PanelWindow {
    id: notifWindow
    anchors {
        top: true
        right: true
    }
    margins.top: 40
    margins.right: 10
    color: "transparent"
    width: 350
    height: 1000

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    
    // This allows clicking through transparent areas in Quickshell
    mask: Region {
        item: listView
    }

    ListModel {
        id: notifModel
    }

    NotificationServer {
        onNotification: notif => {
            notifModel.append({
                "nTitle": notif.summary || "Notification",
                "nBody": notif.body || "",
                "nAppName": notif.appName || "System",
                "uid": Math.random().toString(36).substr(2, 9)
            })
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        model: notifModel
        spacing: 10
        interactive: false
        
        // Populate transition for slide-in animation
        add: Transition {
            NumberAnimation { property: "x"; from: 350; duration: 200; easing.type: Easing.OutQuad }
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
        }
        
        remove: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: 200 }
        }

        delegate: Rectangle {
            width: 350
            height: Math.max(50, bodyText.implicitHeight + titleText.implicitHeight + 25)
            color: Qt.rgba(43/255, 48/255, 59/255, 0.95)
            
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 3
                color: Qt.rgba(100/255, 114/255, 125/255, 0.5)
            }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                width: 3
                color: "#2980b9"
            }

            Text {
                id: titleText
                text: nTitle
                color: "#ffffff"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.bold: true
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 12
                elide: Text.ElideRight
            }

            Text {
                id: bodyText
                text: nBody
                color: "#dddddd"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                wrapMode: Text.Wrap
                anchors.top: titleText.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.topMargin: 2
            }

            Timer {
                interval: 5000
                running: true
                onTriggered: {
                    for(var i=0; i<notifModel.count; i++) {
                        if(notifModel.get(i).uid === uid) {
                            notifModel.remove(i)
                            break
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    for(var i=0; i<notifModel.count; i++) {
                        if(notifModel.get(i).uid === uid) {
                            notifModel.remove(i)
                            break
                        }
                    }
                }
            }
        }
    }
}
