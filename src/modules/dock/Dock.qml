pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.service
import qs.modules.bar.service
import qs.modules.dock

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
                DockWidget {
                    id: content

                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: DockConfig.marginBottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: win.effectiveShouldShow ? DockConfig.visibleOpacity : DockConfig.hiddenOpacity
                    screen: win.modelData

                    Behavior on opacity {
                        NumberAnimation {
                            duration: DockConfig.showAnimMs
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }
}
