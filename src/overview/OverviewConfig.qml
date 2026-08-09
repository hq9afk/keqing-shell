pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

QtObject {
    id: root

    // Animation
    property int animEnterMs: 400
    property int animFastMs: 200
    property Component animFastNumber: Component {
        NumberAnimation {
            duration: root.animFastMs
            easing.type: Easing.OutCubic
        }
    }

    // Layout
    property int backgroundBorderWidth: 1

    // Colors
    property real backgroundOpacity: 1
    property int backgroundPadding: 10
    property int columns: 5
    property real elevationMargin: 10

    // Misc
    property bool enable: true

    // Timing
    property int focusGrabDelayMs: 150
    property int focusedIndicatorBorderWidth: 2

    // Window
    property real iconToWindowRatio: 0.25
    property real otherMonitorOpacity: 0.4
    property int raceDelayMs: 150
    property int rows: 2
    property real scale: 0.15
    property int screenRounding: 23

    // Shadow
    property real shadowBlurFactor: 0.9
    property real shadowOffsetX: 0.0
    property real shadowOffsetY: 1.0
    property int shadowRadius: 20
    property real shadowSpread: 1

    // Tooltip
    property int toolTipHorizontalPadding: 10
    property int toolTipVerticalPadding: 5
    property int tooltipRounding: 8
    property int windowDraggingZ: 99999
    property int windowPreviewBorderWidth: 1
    property int windowRounding: 18

    // Workspace
    property int workspaceBorderWidth: 2
    property int workspaceNumberBaseSize: 250
    property real workspaceNumberTextFade: 0.8
    property real workspaceSpacing: 5
}
