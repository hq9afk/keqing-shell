pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell

import qs.modules.bar
import qs.modules.bar.layout.components
import qs.modules.bar.service
import qs.config

WidgetCapsule {
    id: root

    readonly property var workspaces: {
        CompositorWorkspaceService.rev;
        var pills = CompositorWorkspaceService.pillsForScreen(screen) || [];
        var seen = ({});
        return pills.filter(p => {
            if (seen[p.id])
                return false;
            seen[p.id] = true;
            return true;
        });
    }

    function syncPillModel(model, pills) {
        for (var i = model.count - 1; i >= 0; i--) {
            var id = model.get(i).pillId;
            if (!pills.some(p => p.id === id))
                model.remove(i);
        }
        for (var idx = 0; idx < pills.length && idx <= model.count; idx++) {
            var p = pills[idx];
            var curIdx = -1;
            for (var j = 0; j < model.count; j++) {
                if (model.get(j).pillId === p.id) {
                    curIdx = j;
                    break;
                }
            }
            if (curIdx === -1) {
                model.insert(idx, {
                    "pillId": p.id,
                    "active": p.active === true,
                    "occupied": p.occupied === true,
                    "urgent": p.urgent === true
                });
            } else {
                if (curIdx !== idx)
                    model.move(curIdx, idx, 1);
                if (model.get(idx).active !== (p.active === true))
                    model.setProperty(idx, "active", p.active === true);
                if (model.get(idx).occupied !== (p.occupied === true))
                    model.setProperty(idx, "occupied", p.occupied === true);
                if (model.get(idx).urgent !== (p.urgent === true))
                    model.setProperty(idx, "urgent", p.urgent === true);
            }
        }
    }

    implicitWidth: layout.implicitWidth + BarConfig.widgetContentPaddingH
    panelName: "overview"

    Component.onCompleted: root.syncPillModel(pillModel, root.workspaces)
    onWorkspacesChanged: root.syncPillModel(pillModel, root.workspaces)

    ListModel {
        id: pillModel
    }
    Row {
        id: layout

        anchors.centerIn: parent
        spacing: BarConfig.workspaceLayoutSpacing

        Row {
            id: pills

            anchors.verticalCenter: parent.verticalCenter
            spacing: BarConfig.workspacePillSpacing

            move: Transition {
                NumberAnimation {
                    duration: BarConfig.workspaceReorderAnimMs
                    easing.type: Easing.OutQuad
                    properties: "x,y"
                }
            }

            Repeater {
                model: pillModel

                delegate: Rectangle {
                    id: pill

                    required property bool active
                    property bool flashOn: false
                    readonly property bool isActive: active === true
                    readonly property bool isFlashing: urgent === true
                    readonly property bool isOccupied: occupied === true
                    required property bool occupied
                    required property var pillId
                    required property bool urgent

                    anchors.verticalCenter: parent.verticalCenter
                    color: flashOn ? ColorConfig.lavenderAlpha35 : isActive ? ColorConfig.accentAlt : isOccupied ? ColorConfig.accent : ColorConfig.lavenderAlpha35
                    height: BarConfig.workspacePillHeight
                    radius: height / 2
                    width: isActive ? height * BarConfig.workspaceActiveWidthScale : height

                    Behavior on color {
                        ColorAnimation {
                            duration: BarConfig.workspacePillAnimMs
                        }
                    }
                    Behavior on width {
                        NumberAnimation {
                            duration: BarConfig.workspacePillAnimMs
                        }
                    }

                    onIsFlashingChanged: if (isFlashing)
                        flashAnim.restart()

                    SequentialAnimation {
                        id: flashAnim

                        loops: 3

                        onFinished: if (!CompositorWorkspaceService.isShojiWM)
                            WorkspaceService.flashingIds = ({})

                        PropertyAction {
                            property: "flashOn"
                            target: pill
                            value: true
                        }
                        PauseAnimation {
                            duration: BarConfig.workspaceFlashOnMs
                        }
                        PropertyAction {
                            property: "flashOn"
                            target: pill
                            value: false
                        }
                        PauseAnimation {
                            duration: BarConfig.workspaceFlashOffMs
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: CompositorWorkspaceService.activate(root.screen, pill.pillId)
                    }
                }
            }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            color: ColorConfig.text
            font.family: IconConfig.fontFamily
            font.pixelSize: BarConfig.iconSize
            text: IconConfig.overview

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                onClicked: Quickshell.execDetached(["keqing-shell", "overview"])
            }
        }
    }
}
