pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

QtObject {
    id: root

    // Animation
    readonly property int fadeDuration: 400

    // Opacity
    readonly property real opacityHidden: 0
    readonly property real opacityVisible: 1

    // Screensaver
    readonly property int logoWidth: 200
    readonly property int tickInterval: 33
}
