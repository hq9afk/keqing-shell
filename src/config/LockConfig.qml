pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell

QtObject {
    // Animation
    readonly property int animContentFadeInMs: 350
    readonly property int animContentFadeOutMs: 200
    readonly property int animContentScaleInMs: 400
    readonly property int animContentScaleOutMs: 300
    readonly property int animExpandMs: 400
    readonly property int animFastMs: 100
    readonly property int animIconFadeInMs: 250
    readonly property int animIconFadeOutMs: 300
    readonly property int animNormalMs: 150
    readonly property int animShrinkMs: 350
    readonly property int animSpinMs: 500

    // Background
    readonly property int bgBorderWidth: 5
    readonly property int bgRadius: 10

    // Dots
    readonly property int dotSize: 20
    readonly property int dotSlideOffset: 15

    // Typography
    readonly property int fontDate: 40
    readonly property int fontIcon: 200
    readonly property int fontNormal: 20
    readonly property int fontTime: 100

    // Input
    readonly property int inputHeight: 60
    readonly property int inputRadius: 30
    readonly property int inputWidth: 500

    // Opacity
    readonly property real opacityHidden: 0
    readonly property real opacityVisible: 1

    // Panel
    readonly property int panelGapAvatarUsername: 10
    readonly property int panelGapClockAvatar: 30
    readonly property int panelGapInputMessage: 20
    readonly property int panelGapUsernameInput: 20
    readonly property int panelMargin: 20
    readonly property int panelRadius: 20

    // Profile
    readonly property int profileBorderWidth: 4
    readonly property int profileSize: 200
    readonly property int timerFailMs: 3000

    // Scale
    readonly property real scaleFull: 1
    readonly property real scaleHidden: 0
}
