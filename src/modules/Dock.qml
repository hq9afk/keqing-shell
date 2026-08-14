pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.config
import qs.service

Scope {
    id: root

    IpcHandler {
        function toggle() {
            var screenName = CompositorWorkspaceService.focusedScreenName();
            if (!screenName) {
                SettingsService.adapter.dock.autohideEnabled = !SettingsService.adapter.dock.autohideEnabled;
                SettingsService.save();
                return;
            }
            var current = SettingsService.dockValue(screenName, "autohideEnabled");
            SettingsService.setDockOverrideEnabled(screenName, true);
            SettingsService.setDockValue(screenName, "autohideEnabled", !current);
        }
        function toggleAll() {
            var screenName = CompositorWorkspaceService.focusedScreenName();
            var current = screenName ? SettingsService.dockValue(screenName, "autohideEnabled") : SettingsService.adapter.dock.autohideEnabled;
            var screens = Quickshell.screens;
            for (var i = 0; i < screens.length; i++) {
                SettingsService.setDockOverrideEnabled(screens[i].name, true);
                SettingsService.setDockValue(screens[i].name, "autohideEnabled", !current);
            }
        }

        target: "dock"
    }
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: win

                readonly property bool autohide: SettingsService.dockValueForScreen(win.modelData, "autohideEnabled")
                readonly property bool effectiveShouldShow: !win.autohide || win.shouldShow
                readonly property int fullHeight: DockConfig.marginBottom + content.implicitHeight
                required property var modelData
                readonly property bool shouldShow: hoverHandler.hovered

                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "qs-dock"
                color: "transparent"
                exclusiveZone: SettingsService.loaded && !win.autohide ? win.fullHeight : 0
                implicitHeight: win.effectiveShouldShow || content.opacity > 0 ? win.fullHeight : 1
                screen: win.modelData
                visible: DisplayService.showDock(win.modelData) && content.windows.length > 0

                anchors {
                    bottom: true
                    left: true
                    right: true
                }
                HoverHandler {
                    id: hoverHandler
                }
                Item {
                    id: content

                    readonly property int displayActiveId: DockService.activeWorkspaceId(content.screen)
                    property var screen: win.modelData
                    readonly property var windows: DockService.windowsForWorkspace(content.displayActiveId)

                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: DockConfig.marginBottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitHeight: DockConfig.capsuleHeight
                    implicitWidth: layout.implicitWidth + DockConfig.paddingH * 2
                    opacity: win.effectiveShouldShow ? DockConfig.visibleOpacity : DockConfig.hiddenOpacity
                    visible: content.windows.length > 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: DockConfig.showAnimMs
                            easing.type: Easing.OutCubic
                        }
                    }

                    Component.onCompleted: DockService.syncModel(windowModel, content.windows)
                    onWindowsChanged: DockService.syncModel(windowModel, content.windows)

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
            }
        }
    }
}
