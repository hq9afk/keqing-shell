pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

QtObject {
    id: root

    // Window
    readonly property int marginBottom: 30
    readonly property int panelHeight: 50
    readonly property int panelWidth: 280

    // Timing
    readonly property int hideDelay: 2000
    readonly property int readyDelay: 1000

    // Opacity
    readonly property real opacityHidden: 0
    readonly property real opacityVisible: 1

    // Scale
    readonly property real scaleHidden: 0.92
    readonly property real scaleVisible: 1

    // Content
    readonly property int contentMargin: 14
    readonly property int labelWidth: 44

    // Bar
    readonly property int barHeight: 6
    readonly property int barMargin: 10
    readonly property int barRadius: 3
}
