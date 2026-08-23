pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

import qs.config

QtObject {
    // Capsule
    readonly property int borderWidth: GlobalConfig.borderWidthThin
    readonly property int capsuleHeight: 52
    readonly property int paddingH: 12
    readonly property int radius: GlobalConfig.radiusMd

    // Icons
    readonly property real iconFocusedOpacity: 1
    readonly property int iconMoveAnimMs: 200
    readonly property int iconOpacityAnimMs: 150
    readonly property int iconSize: 22
    readonly property int iconSpacing: 10
    readonly property real iconUnfocusedOpacity: 0.5

    // Window
    readonly property real hiddenOpacity: 0
    readonly property int marginBottom: 10
    readonly property int showAnimMs: 300
    readonly property real visibleOpacity: 1
}
