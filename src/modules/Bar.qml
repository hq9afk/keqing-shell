pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.service
import qs.bar.components
import qs.bar.popups
import qs.config
import qs.modules

Scope {
    id: root

    IpcHandler {
        function toggle() {
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
        function toggleAll() {
            var screenName = CompositorWorkspaceService.focusedScreenName();
            var current = screenName ? SettingsService.barValue(screenName, "autohideEnabled") : SettingsService.adapter.bar.autohideEnabled;
            var screens = Quickshell.screens;
            for (var i = 0; i < screens.length; i++) {
                SettingsService.setBarOverrideEnabled(screens[i].name, true);
                SettingsService.setBarValue(screens[i].name, "autohideEnabled", !current);
            }
        }

        target: "bar"
    }
    Variants {
        model: Quickshell.screens

        delegate: Component {
            Scope {
                id: screenScope

                required property var modelData
                readonly property var screenWidgets: SettingsService._defaultWidgets

                PanelWindow {
                    id: win

                    readonly property bool autohide: SettingsService.barValueForScreen(screenScope.modelData, "autohideEnabled")
                    readonly property bool effectiveShouldShow: !win.autohide || win.shouldShow
                    readonly property int fullHeight: BarConfig.barMarginTop + BarConfig.barHeight
                    readonly property bool panelOpenHere: PanelService.openedScreenName === screenScope.modelData.name || PanelService.closingScreenName === screenScope.modelData.name || (PanelService.getPopupMenuWindow(screenScope.modelData)?.visible ?? false) || ModuleStates.isOpenedFromBarOnScreen(screenScope.modelData.name)
                    readonly property bool shouldShow: hoverHandler.hovered || win.panelOpenHere

                    WlrLayershell.layer: WlrLayer.Top
                    color: "transparent"
                    exclusiveZone: SettingsService.loaded && !win.autohide ? win.fullHeight : 0
                    implicitHeight: win.effectiveShouldShow || content.opacity > 0 ? win.fullHeight : 1
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
