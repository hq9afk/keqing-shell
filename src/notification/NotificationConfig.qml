pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

QtObject {
    // Animation
    readonly property int animExitBuffer: 60
    readonly property int animFast: 150
    readonly property int animNormal: 220

    // Typography
    readonly property int fontAppName: 13
    readonly property int fontBody: 15
    readonly property int fontSummary: 17

    // Card
    readonly property int cardBorderWidth: 2
    readonly property int cardExtraHeight: 8
    readonly property int cardPadding: 16
    readonly property int cardRadius: 10
    readonly property int cardSlideOffset: 24
    readonly property int cardSpacing: 8
    readonly property int cardSwipeDismissThreshold: 80
    readonly property int cardSwipeExitOffset: 20
    readonly property int cardWidth: 400

    // Content
    readonly property int appNameMaxWidthInset: 12
    readonly property int cardContentSpacing: 10
    readonly property int cardContentTrailingGap: 8
    readonly property int headerRowSpacing: 6

    // Progress
    readonly property int progressBarFillDuration: 100
    readonly property int progressBarHeight: 4
    readonly property int progressTickInterval: 100
    readonly property real progressTrackOpacity: 0.3

    // Urgency
    readonly property int urgencyDotRadius: 3
    readonly property int urgencyDotSize: 6

    // Close
    readonly property int closeHitAreaSize: 32
    readonly property real closeIconOpacityIdle: 0.4

    // State
    readonly property real opacityAppNameDim: 0.65
    readonly property real opacityBodyDim: 0.72
    readonly property real opacityHidden: 0.0
    readonly property real opacityVisible: 1.0

    // Screen
    readonly property int screenMargin: 10
}
