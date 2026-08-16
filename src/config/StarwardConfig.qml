pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

QtObject {
    // Actions
    readonly property var actionsChars: ["劍", "光", "如", "我", "斬", "盡", "蕪", "雜"]
    readonly property var actionsCommands: ["systemctl poweroff", "systemctl reboot", "qs -c keqing-shell ipc call lock toggle", "systemctl reboot --firmware-setup"]

    // Buttons
    property int buttonBorderAnimMs: 160
    property int buttonBorderWidth: 5

    property int buttonCornerRadiusDiv: 5
    property real buttonHiddenOpacity: 0
    property real buttonHighlightScale: 1.05
    property int buttonOpacityAnimMs: 150
    property int buttonRadiusAnimMs: 150
    property int buttonScaleAnimMs: 140
    property int buttonSize: 110
    property real buttonVisibleOpacity: 1

    // Layout
    property int buttonsCount: 8
    property int buttonsExpandedRadius: 300
    property int buttonsStaggerMs: 100
    property real buttonsStartAngle: -Math.PI / 2
    property real buttonsStepAngle: Math.PI / 4

    // Logo
    property int logoAnimMs: 600
    property int logoSize: 250
    property int logoBorderWidth: 5
}
