pragma ComponentBehavior: Bound

import QtQuick

import qs.modules.settings
import qs.config

Column {
    id: root

    default property alias content: inner.data
    property int contentSpacing: 0
    property bool flat: false
    property string title: ""

    spacing: SettingsConfig.groupSpacing

    Text {
        color: ColorConfig.text
        font.family: FontConfig.fontFamily
        font.pixelSize: FontConfig.fontSettingsBody
        font.weight: Font.DemiBold
        opacity: SettingsConfig.dimTextOpacity
        text: root.title
        visible: root.title !== ""
    }
    Item {
        implicitHeight: root.flat ? inner.implicitHeight : inner.implicitHeight + SettingsConfig.groupExtraHeight
        width: root.width

        Rectangle {
            anchors.fill: parent
            border.color: ColorConfig.textAlpha07
            border.width: SettingsConfig.hairlineBorderWidth
            color: ColorConfig.textAlpha04
            radius: SettingsConfig.groupRadius
            visible: !root.flat
        }
        Column {
            id: inner

            anchors.left: parent.left
            anchors.leftMargin: root.flat ? 0 : SettingsConfig.groupPadding
            anchors.right: parent.right
            anchors.rightMargin: root.flat ? 0 : SettingsConfig.groupPadding
            anchors.top: parent.top
            anchors.topMargin: root.flat ? 0 : SettingsConfig.groupPadding
            spacing: root.contentSpacing
        }
    }
}
