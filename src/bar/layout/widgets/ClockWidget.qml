pragma ComponentBehavior: Bound

import QtQuick

import qs.service
import qs.bar
import qs.bar.layout.components
import qs.bar.service
import qs.config

WidgetCapsule {
    id: root

    implicitWidth: label.implicitWidth + BarConfig.widgetContentPaddingH

    Text {
        id: label

        anchors.centerIn: parent
        color: ColorConfig.text
        font.family: FontConfig.fontFamily
        font.pixelSize: FontConfig.fontBody
        text: Qt.formatDateTime(DateTimeService.date, config.format || "ddd yyyy-MM-dd hh:mm:ss")
    }
    MouseArea {
        acceptedButtons: Qt.LeftButton
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: PanelService.getPanel("clockPanel", root.screen)?.toggle(root)
    }
}
