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
import qs.modules.core

Scope {
    id: root

    IpcHandler {
        function toggleAutohide() {
            var screenName = CompositorWorkspaceService.focusedScreenName();
            if (!screenName) {
                SettingsService.adapter.bar.autohideEnabled = !SettingsService.adapter.bar.autohideEnabled;
                SettingsService.save();
                return;
            }
            var current = SettingsService.barValue(screenName, "autohideEnabled");
            SettingsService.setBarOverrideEnabled(screenName, true);
            SettingsService.setBarValue(screenName, "autohideEnabled", !current);
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

                PanelWindow {
                    id: win

                    readonly property bool autohide: SettingsService.barValueForScreen(screenScope.modelData, "autohideEnabled")
                    readonly property bool effectiveShouldShow: !win.autohide || win.shouldShow
                    readonly property int fullHeight: BarConfig.barMarginTop + BarConfig.barHeight
                    readonly property bool panelOpenHere: PanelService.openedScreenName === screenScope.modelData.name || PanelService.closingScreenName === screenScope.modelData.name || (PanelService.getPopupMenuWindow(screenScope.modelData)?.visible ?? false) || ModuleStates.isOpenedFromBarOnScreen(screenScope.modelData.name)
                    readonly property bool shouldShow: hoverHandler.hovered || win.panelOpenHere

                    WlrLayershell.layer: WlrLayer.Top
                    color: "transparent"
                    exclusiveZone: win.autohide ? 0 : win.fullHeight
                    implicitHeight: win.effectiveShouldShow || content.opacity > 0 ? win.fullHeight : 1
                    screen: screenScope.modelData
                    visible: DisplayService.showBar(screenScope.modelData)

                    anchors {
                        left: true
                        right: true
                        top: true
                    }
                    margins {
                        left: BarConfig.barMarginH
                        right: BarConfig.barMarginH
                    }
                    HoverHandler {
                        id: hoverHandler
                    }
                    Item {
                        id: content

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: BarConfig.barMarginTop
                        height: BarConfig.barHeight
                        opacity: win.effectiveShouldShow ? BarConfig.barVisibleOpacity : BarConfig.barHiddenOpacity

                        Behavior on opacity {
                            NumberAnimation {
                                duration: BarConfig.barContentFadeMs
                                easing.type: Easing.OutCubic
                            }
                        }

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
