pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

import qs.config

QtObject {
    // Mode
    readonly property string mode: "ring"

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

    // Sphere
    readonly property real sphereOpacity: 0.85
    readonly property list<color> sphereGradient: [ColorConfig.accent]
    readonly property real sphereRadius: 120
    readonly property real sphereFeather: 0.15
    readonly property real sphereRadiusAudioMultiplier: 40
    readonly property real sphereNoiseFrequency: 1.4
    readonly property real sphereNoiseAmplitude: 18
    readonly property real sphereNoiseSpeed: 0.6

    // Ring
    readonly property real ringOpacity: 0.85
    readonly property list<color> ringGradient: [ColorConfig.accent]
    readonly property real ringBaseRadius: 80
    readonly property real ringMaxBarHeight: 60
    readonly property real ringBarThicknessRatio: 0.8
    readonly property int ringAnimDurationMs: 60

    // Window
    readonly property int contentFadeAnimMs: 200
    readonly property int defaultWindowHeight: 350
    readonly property real hiddenOpacity: 0
    readonly property real visibleOpacity: 1
    readonly property color windowBackground: Qt.rgba(0, 0, 0, 0.7)
}
