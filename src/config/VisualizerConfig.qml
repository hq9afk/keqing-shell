pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

import qs.config

QtObject {
    // Bar
    readonly property real barOpacity: 0.6
    readonly property list<color> barGradient: [ColorConfig.accent]
    readonly property real barHeightRatio: 0.7
    readonly property int barRadius: 3
    readonly property int barSpacing: 7
    readonly property int barWidth: 10

    // Spectrum
    readonly property int barCount: 100
    readonly property int barsAnimDurationMs: 60

    // Window
    readonly property int contentFadeAnimMs: 200
    readonly property int defaultWindowHeight: 350
    readonly property real hiddenOpacity: 0
    readonly property real visibleOpacity: 1
    readonly property color windowBackground: Qt.rgba(0, 0, 0, 0.7)
}
