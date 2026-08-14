pragma ComponentBehavior: Bound

import QtQuick

import qs.service
import qs.bar.components
import qs.config

WidgetCapsule {
    id: root

    readonly property real temp: SystemStatService.cpuTempC
    readonly property real usage: SystemStatService.cpuUsage

    iconGlyph: IconConfig.cpu
    labelText: Math.round(usage).toString().padStart(3) + "%" + (temp > 0 ? " " + temp.toString().padStart(3) + "°" : "")
    panelName: "systemMonitorPanel"
    showLabel: baseShowLabel

    MouseArea {
        acceptedButtons: Qt.LeftButton
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: PanelService.getPanel("systemMonitorPanel", root.screen)?.toggle(root)
    }
}
