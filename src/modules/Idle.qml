pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.config
import qs.service
import qs.elements

Scope {
    IpcHandler {
        function disable() {
            SettingsService.setIdleEnabled(false);
        }
        function enable() {
            SettingsService.setIdleEnabled(true);
        }
        function toggle() {
            SettingsService.setIdleEnabled(!SettingsService.adapter.idle.enabled);
        }

        target: "idle"
    }
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: idleWindow

                readonly property bool blackoutShouldShow: SettingsService.idleValueForScreen(idleWindow.modelData, "screensaverEnabled") && !idleWindow.isHeadless && IdleService.isIdle(idleWindow.modelData, SettingsService.idleValueForScreen(idleWindow.modelData, "screensaverTimeoutSeconds") * 1000)
                readonly property bool isHeadless: idleWindow.modelData.name === "HEADLESS"
                required property var modelData
                readonly property bool wallpaperShouldShow: SettingsService.idleValueForScreen(idleWindow.modelData, "ambientEnabled") && !idleWindow.isHeadless && IdleService.isIdle(idleWindow.modelData, SettingsService.idleValueForScreen(idleWindow.modelData, "ambientTimeoutSeconds") * 1000)

                WlrLayershell.layer: WlrLayer.Overlay
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                screen: idleWindow.modelData
                visible: wallpaperContent.opacity > 0 || blackContent.opacity > 0 || wallpaperShouldShow || blackoutShouldShow

                anchors {
                    bottom: true
                    left: true
                    right: true
                    top: true
                }
                Item {
                    id: wallpaperContent

                    anchors.fill: parent
                    opacity: idleWindow.wallpaperShouldShow ? IdleConfig.opacityVisible : IdleConfig.opacityHidden

                    Behavior on opacity {
                        NumberAnimation {
                            duration: IdleConfig.fadeDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    Repeater {
                        model: WallpaperService.animatedEnabled ? (WallpaperService.animatedColumns[idleWindow.modelData.name] ?? 1) : (WallpaperService.staticColumns[idleWindow.modelData.name] ?? 1)

                        delegate: WallpaperColumn {
                            required property int index

                            columnCount: WallpaperService.animatedEnabled ? (WallpaperService.animatedColumns[idleWindow.modelData.name] ?? 1) : (WallpaperService.staticColumns[idleWindow.modelData.name] ?? 1)
                            columnIndex: index
                            paused: !idleWindow.wallpaperShouldShow || idleWindow.blackoutShouldShow
                            screenName: idleWindow.modelData.name
                        }
                    }
                }
                Item {
                    id: blackContent

                    anchors.fill: parent
                    opacity: idleWindow.blackoutShouldShow ? IdleConfig.opacityVisible : IdleConfig.opacityHidden

                    Behavior on opacity {
                        NumberAnimation {
                            duration: IdleConfig.fadeDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                    }
                    Item {
                        id: screenSaver

                        readonly property bool active: idleWindow.blackoutShouldShow
                        readonly property int logoHeight: logoImage.height
                        readonly property int logoWidth: IdleConfig.logoWidth
                        property real posX: 0
                        property real posY: 0
                        property real velX: 5
                        property real velY: 5

                        function randomizeStart() {
                            screenSaver.posX = Math.random() * Math.max(1, screenSaver.width - screenSaver.logoWidth);
                            screenSaver.posY = Math.random() * Math.max(1, screenSaver.height - screenSaver.logoHeight);
                            screenSaver.velX = (Math.random() < 0.5 ? -1 : 1) * (1.5 + Math.random());
                            screenSaver.velY = (Math.random() < 0.5 ? -1 : 1) * (1.5 + Math.random());
                        }

                        anchors.fill: parent

                        onActiveChanged: {
                            if (screenSaver.active)
                                screenSaver.randomizeStart();
                        }

                        Timer {
                            interval: IdleConfig.tickInterval
                            repeat: true
                            running: screenSaver.active && screenSaver.width > screenSaver.logoWidth && screenSaver.height > screenSaver.logoHeight

                            onTriggered: {
                                var nx = screenSaver.posX + screenSaver.velX;
                                var ny = screenSaver.posY + screenSaver.velY;
                                var maxX = screenSaver.width - screenSaver.logoWidth;
                                var maxY = screenSaver.height - screenSaver.logoHeight;

                                if (nx <= 0) {
                                    nx = 0;
                                    screenSaver.velX = Math.abs(screenSaver.velX);
                                } else if (nx >= maxX) {
                                    nx = maxX;
                                    screenSaver.velX = -Math.abs(screenSaver.velX);
                                }
                                if (ny <= 0) {
                                    ny = 0;
                                    screenSaver.velY = Math.abs(screenSaver.velY);
                                } else if (ny >= maxY) {
                                    ny = maxY;
                                    screenSaver.velY = -Math.abs(screenSaver.velY);
                                }

                                screenSaver.posX = nx;
                                screenSaver.posY = ny;
                            }
                        }
                        Image {
                            id: logoImage

                            layer.enabled: true
                            smooth: true
                            source: GlobalConfig.defaultWallpaper
                            sourceSize.width: screenSaver.logoWidth
                            x: screenSaver.posX
                            y: screenSaver.posY

                            layer.effect: MultiEffect {
                                colorization: 1
                                colorizationColor: ColorConfig.accent
                            }
                        }
                    }
                }
            }
        }
    }
}
