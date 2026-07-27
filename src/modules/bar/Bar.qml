pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.service
import qs.modules.bar
import qs.modules.bar.layout.components
import qs.modules.bar.layout.popups
import qs.modules.bar.service

Scope {
    id: root

    IpcHandler {
        function toggle() {
            var screenName = CompositorWorkspaceService.focusedScreenName();
            if (!screenName)
                return;
            SettingsService.setBarLoaderOpen(screenName, !SettingsService.barLoaderOpen(screenName));
        }
        function toggleAll() {
            var screens = Quickshell.screens;
            var anyOpen = false;
            for (var i = 0; i < screens.length; i++) {
                if (SettingsService.barLoaderOpen(screens[i].name)) {
                    anyOpen = true;
                    break;
                }
            }
            for (var j = 0; j < screens.length; j++)
                SettingsService.setBarLoaderOpen(screens[j].name, !anyOpen);
        }

        target: "bar"
    }
    Variants {
        model: Quickshell.screens

        delegate: Component {
            Scope {
                id: screenScope

                required property var modelData
                readonly property var screenWidgets: {
                    var all = SettingsService.allWidgets;
                    var sn = screenScope.modelData.name;
                    var sm = screenScope.modelData.model;
                    var entry = all[sn] || all[sm];
                    if (!entry || entry._enabled === false)
                        entry = all["default"] || SettingsService._defaultWidgets;
                    var def = SettingsService._defaultWidgets;
                    return {
                        left: entry.left || def.left,
                        center: entry.center || def.center,
                        right: entry.right || def.right
                    };
                }

                Loader {
                    active: SettingsService.barLoaderOpen(screenScope.modelData.name)

                    sourceComponent: Component {
                        Item {
                            PanelWindow {
                                id: win

                                readonly property int fullHeight: BarConfig.barMarginTop + BarConfig.barHeight

                                WlrLayershell.layer: WlrLayer.Top
                                color: "transparent"
                                exclusiveZone: win.fullHeight
                                implicitHeight: win.fullHeight
                                screen: screenScope.modelData

                                anchors {
                                    left: true
                                    right: true
                                    top: true
                                }
                                margins {
                                    left: BarConfig.barMarginH
                                    right: BarConfig.barMarginH
                                }
                                Item {
                                    id: content

                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.topMargin: BarConfig.barMarginTop
                                    height: BarConfig.barHeight

                                    Rectangle {
                                        anchors.fill: parent
                                        color: Qt.rgba(0, 0, 0, BarConfig.backgroundOpacity)
                                    }
                                    BarRegion {
                                        position: "left"
                                        screen: screenScope.modelData
                                        widgets: screenScope.screenWidgets.left
                                    }
                                    BarRegion {
                                        position: "center"
                                        screen: screenScope.modelData
                                        widgets: screenScope.screenWidgets.center
                                    }
                                    BarRegion {
                                        position: "right"
                                        screen: screenScope.modelData
                                        widgets: screenScope.screenWidgets.right
                                    }
                                }
                            }
                            PopupOverlay {
                                screen: screenScope.modelData
                            }
                            PopupMenuWindow {
                                screen: screenScope.modelData
                            }
                        }
                    }
                }
            }
        }
    }
}
