pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell

import qs.bar.components
import qs.config
import qs.service

WidgetCapsule {
    id: root

    readonly property int displayActiveId: DockService.activeWorkspaceId(root.screen)
    readonly property var windows: DockService.windowsForWorkspace(root.displayActiveId)

    implicitWidth: layout.implicitWidth + BarConfig.widgetContentPaddingH
    visible: root.windows.length > 0

    Component.onCompleted: DockService.syncModel(windowModel, root.windows)
    onWindowsChanged: DockService.syncModel(windowModel, root.windows)

    ListModel {
        id: windowModel
    }
    Row {
        id: layout

        anchors.centerIn: parent
        spacing: BarConfig.widgetSpacing

        move: Transition {
            NumberAnimation {
                duration: BarConfig.dockReorderAnimMs
                easing.type: Easing.OutQuad
                properties: "x,y"
            }
        }

        Repeater {
            model: windowModel

            delegate: Image {
                id: icon

                required property string address
                readonly property var entry: DesktopEntries.heuristicLookup(wsClass)
                readonly property bool isFocused: DockService.isFocused(address)
                required property string wsClass

                anchors.verticalCenter: parent.verticalCenter
                height: BarConfig.iconSize
                opacity: isFocused ? BarConfig.dockIconFocusedOpacity : BarConfig.dockIconUnfocusedOpacity
                source: Quickshell.iconPath(entry?.icon || wsClass || "application-x-executable") || ""
                sourceSize: Qt.size(height, height)
                width: height

                Behavior on opacity {
                    NumberAnimation {
                        duration: BarConfig.dockIconAnimMs
                    }
                }
            }
        }
    }
}
