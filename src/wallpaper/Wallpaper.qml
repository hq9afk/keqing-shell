pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.service
import qs.components

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: screenWindow

                required property var modelData
                readonly property bool screensaverActive: SettingsService.idleValueForScreen(screenWindow.modelData, "screensaverEnabled") && IdleService.isIdle(screenWindow.modelData, SettingsService.idleValueForScreen(screenWindow.modelData, "screensaverTimeoutSeconds") * 1000)

                WlrLayershell.layer: WlrLayer.Background
                color: "black"
                exclusionMode: ExclusionMode.Ignore
                screen: modelData

                anchors {
                    bottom: true
                    left: true
                    right: true
                    top: true
                }
                Repeater {
                    model: WallpaperService.animatedEnabled ? 0 : (WallpaperService.staticColumns[screenWindow.modelData.name] ?? 1)

                    delegate: StaticRegion {
                        required property int index

                        columnCount: WallpaperService.staticColumns[screenWindow.modelData.name] ?? 1
                        columnIndex: index
                        screenName: screenWindow.modelData.name
                    }
                }
                Repeater {
                    model: WallpaperService.animatedEnabled ? (WallpaperService.animatedColumns[screenWindow.modelData.name] ?? 1) : 0

                    delegate: AnimatedRegion {
                        required property int index

                        columnCount: WallpaperService.animatedColumns[screenWindow.modelData.name] ?? 1
                        columnIndex: index
                        paused: screenWindow.screensaverActive || LockService.locked
                        screenName: screenWindow.modelData.name
                    }
                }
            }
        }
    }
}
