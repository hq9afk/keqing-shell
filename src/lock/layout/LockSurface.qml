pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell.Wayland

import qs.service
import qs.components
import qs.lock
import qs.config

WlSessionLockSurface {
    id: root

    required property WlSessionLock sessionLock

    signal authenticate(string pass)
    signal closed

    // Wallpaper
    Rectangle {
        anchors.fill: parent
        color: "black"

        Repeater {
            model: WallpaperService.animatedEnabled ? 0 : (WallpaperService.staticColumns[root.screen?.name ?? ""] ?? 1)

            delegate: StaticRegion {
                required property int index

                columnCount: WallpaperService.staticColumns[root.screen?.name ?? ""] ?? 1
                columnIndex: index
                screenName: root.screen?.name ?? ""
            }
        }
        Repeater {
            model: WallpaperService.animatedEnabled ? (WallpaperService.animatedColumns[root.screen?.name ?? ""] ?? 1) : 0

            delegate: AnimatedRegion {
                required property int index

                columnCount: WallpaperService.animatedColumns[root.screen?.name ?? ""] ?? 1
                columnIndex: index
                screenName: root.screen?.name ?? ""
            }
        }
    }

    // Debug unlock
    Button {
        anchors.bottom: parent.bottom
        opacity: LockConfig.opacityHidden
        z: 100

        onClicked: root.sessionLock.beginUnlock()
    }

    // UI layer — hidden on displays where lock is disabled
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        opacity: DisplayService.showLock(root.screen) ? LockConfig.opacityVisible : LockConfig.opacityHidden

        LockPanel {
            anchors.centerIn: parent
            failed: root.sessionLock.failed
            unlocking: root.sessionLock.unlocking

            onAuthenticate: pass => root.authenticate(pass)
            onFailedReset: root.sessionLock.failed = false
            onUnlockFinished: {
                root.sessionLock.locked = false;
                if (!root.sessionLock.animDoneEmitted) {
                    root.sessionLock.animDoneEmitted = true;
                    root.closed();
                }
            }
        }
        Timer {
            interval: LockConfig.timerFailMs
            running: root.sessionLock.failed

            onTriggered: root.sessionLock.failed = false
        }
    }
}
