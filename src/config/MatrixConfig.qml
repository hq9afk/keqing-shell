pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

import qs.config

QtObject {
    id: root

    // Grid
    readonly property int fontPixelSize: 20
    readonly property FontMetrics fontMetrics: FontMetrics {
        font.family: FontConfig.fontFamily
        font.pixelSize: root.fontPixelSize
    }
    readonly property int cellHeight: fontMetrics.height
    readonly property int cellWidth: fontMetrics.averageCharacterWidth

    // Rain
    readonly property real boldChance: 0.5
    readonly property real fadeAlpha: 0.05
    readonly property int fallIntervalMs: 45
    readonly property string glyphPool: {
        var katakana = "";
        for (var i = 0xFF66; i <= 0xFF9D; i++)
            katakana += String.fromCharCode(i);
        var numbers = "1234567890";
        var symbols = "-=*_+|:<>\"";
        return katakana + numbers.repeat(2) + symbols.repeat(4);
    }
    readonly property real resetChance: 0.025

    // Window
    readonly property int contentFadeAnimMs: 200
    readonly property int defaultWindowHeight: 600
    readonly property int defaultWindowWidth: 480
    readonly property real hiddenOpacity: 0
    readonly property real visibleOpacity: 1
    readonly property color windowBackground: Qt.rgba(0, 0, 0, 0.7)
}
