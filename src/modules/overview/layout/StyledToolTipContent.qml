pragma ComponentBehavior: Bound

import QtQuick

import qs.config

Item {
    id: root

    property real horizontalPadding: OverviewConfig.toolTipHorizontalPadding
    property bool isVisible: backgroundRectangle.implicitHeight > 0
    property bool shown: false
    required property string text
    property real verticalPadding: OverviewConfig.toolTipVerticalPadding

    implicitHeight: tooltipTextObject.implicitHeight + 2 * root.verticalPadding
    implicitWidth: tooltipTextObject.implicitWidth + 2 * root.horizontalPadding

    Rectangle {
        id: backgroundRectangle

        clip: true
        color: ColorConfig.fieldBg
        implicitHeight: shown ? (tooltipTextObject.implicitHeight + 2 * root.verticalPadding) : 0
        implicitWidth: shown ? (tooltipTextObject.implicitWidth + 2 * root.horizontalPadding) : 0
        opacity: shown ? 1 : 0
        radius: OverviewConfig.tooltipRounding

        Behavior on implicitHeight {
            animation: OverviewConfig.animFastNumber.createObject(this)
        }
        Behavior on implicitWidth {
            animation: OverviewConfig.animFastNumber.createObject(this)
        }
        Behavior on opacity {
            animation: OverviewConfig.animFastNumber.createObject(this)
        }

        anchors {
            bottom: root.bottom
            horizontalCenter: root.horizontalCenter
        }
        StyledText {
            id: tooltipTextObject

            anchors.centerIn: parent
            color: ColorConfig.text
            font.hintingPreference: Font.PreferNoHinting
            font.pixelSize: FontConfig.fontTooltip
            text: root.text
            wrapMode: Text.Wrap
        }
    }
}
