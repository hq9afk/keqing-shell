pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import KeqingShell.Matrix

import qs.config
import qs.matrix

FloatingWindow {
    id: window

    required property bool isOpen

    color: MatrixConfig.windowBackground
    implicitHeight: MatrixConfig.defaultWindowHeight
    implicitWidth: MatrixConfig.defaultWindowWidth
    visible: content.opacity > 0 || window.isOpen

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
