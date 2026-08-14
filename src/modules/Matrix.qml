pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import KeqingShell.Matrix

import qs.config
import qs.modules

ModuleLoader {
    id: root

    module: "matrix"

    sourceComp: Component {
        Scope {
            id: panel

            property alias controller: controller

            signal closeRequested

            // Controller
            Item {
                id: controller

                property bool isOpen: false

                function close() {
                    isOpen = false;
                }
                function open() {
                    isOpen = true;
                }
                function toggle() {
                    if (isOpen)
                        close();
                    else
                        open();
                }
            }

            // Window
            FloatingWindow {
                id: window

                property bool isOpen: controller.isOpen

                color: MatrixConfig.windowBackground
                implicitHeight: MatrixConfig.defaultWindowHeight
                implicitWidth: MatrixConfig.defaultWindowWidth
                visible: content.opacity > 0 || window.isOpen

                onClosed: panel.closeRequested()

                Item {
                    id: content

                    anchors.fill: parent
                    opacity: window.isOpen ? MatrixConfig.visibleOpacity : MatrixConfig.hiddenOpacity

                    Behavior on opacity {
                        NumberAnimation {
                            duration: MatrixConfig.contentFadeAnimMs
                            easing.type: Easing.OutCubic

                            onRunningChanged: {
                                if (!running && !window.isOpen && content.opacity === 0)
                                    window.closed();
                            }
                        }
                    }

                    MatrixGrid {
                        id: grid

                        anchors.fill: parent
                        boldChance: MatrixConfig.boldChance
                        cellHeight: MatrixConfig.cellHeight
                        cellWidth: MatrixConfig.cellWidth
                        fadeAlpha: MatrixConfig.fadeAlpha
                        fallIntervalMs: MatrixConfig.fallIntervalMs
                        font.family: FontConfig.fontFamily
                        font.pixelSize: MatrixConfig.fontPixelSize
                        glyphs: MatrixConfig.glyphPool
                        headColor: ColorConfig.text
                        resetChance: MatrixConfig.resetChance
                        running: window.isOpen
                        tailColor: ColorConfig.accent
                    }
                }
            }
        }
    }

    IpcHandler {
        function toggle() {
            root.toggle();
        }

        target: "matrix"
    }
}
