pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell

import qs.config
import qs.dock
import qs.service

Item {
    id: root

    readonly property int displayActiveId: DockService.activeWorkspaceId(root.screen)
    property var screen: null
    readonly property var windows: DockService.windowsForWorkspace(root.displayActiveId)

    implicitHeight: DockConfig.capsuleHeight
    implicitWidth: layout.implicitWidth + DockConfig.paddingH * 2
    visible: root.windows.length > 0

    Component.onCompleted: DockService.syncModel(windowModel, root.windows)
    onWindowsChanged: DockService.syncModel(windowModel, root.windows)

    ListModel {
        id: windowModel
    }
    Rectangle {
        anchors.fill: parent
        border.color: ColorConfig.accent
        border.width: DockConfig.borderWidth
        color: ColorConfig.overlay
        radius: DockConfig.radius
    }
    Row {
        id: layout

        anchors.centerIn: parent
        spacing: DockConfig.iconSpacing

        move: Transition {
            NumberAnimation {
                duration: DockConfig.iconMoveAnimMs
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
                height: DockConfig.iconSize
                opacity: isFocused ? DockConfig.iconFocusedOpacity : DockConfig.iconUnfocusedOpacity
                source: Quickshell.iconPath(entry?.icon || wsClass || "application-x-executable") || ""
                sourceSize: Qt.size(height, height)
                width: height

                Behavior on opacity {
                    NumberAnimation {
                        duration: DockConfig.iconOpacityAnimMs
                    }
                }
            }
        }
    }
}
