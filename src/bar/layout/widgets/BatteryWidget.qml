pragma ComponentBehavior: Bound

import QtQuick

import qs.service
import qs.bar
import qs.bar.layout.components
import qs.bar.service
import qs.config

WidgetCapsule {
    id: root

    borderColor: {
        if (!BatteryService.detected)
            return ColorConfig.accent;
        if (BatteryService.allFull)
            return ColorConfig.text;
        if (BatteryService.anyCharging)
            return ColorConfig.accentAlt;
        if (BatteryService.pct <= 25)
            return "#ff5555";
        return ColorConfig.accent;
    }
    iconGlyph: {
        if (!BatteryService.detected)
            return IconConfig.batteryDisabled;
        if (BatteryService.allFull)
            return IconConfig.pluggedIn;
        if (BatteryService.anyCharging)
            return IconConfig.batteryCharging;
        if (BatteryService.pct <= 25)
            return IconConfig.battery1;
        if (BatteryService.pct <= 50)
            return IconConfig.battery2;
        if (BatteryService.pct <= 75)
            return IconConfig.battery3;
        return IconConfig.battery4;
    }
    labelText: {
        if (!BatteryService.detected)
            return "No Battery Detected";
        return BatteryService.allFull ? "Plugged in" : BatteryService.pct.toString().padStart(3) + "%";
    }
    panelName: "batteryPanel"
    showLabel: baseShowLabel

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(1, 0, 0, 0.15)
        radius: BarConfig.capsuleRadius
        visible: !BatteryService.anyCharging && !BatteryService.allFull && BatteryService.pct <= 10
    }
    MouseArea {
        acceptedButtons: Qt.LeftButton
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: PanelService.getPanel("batteryPanel", root.screen)?.toggle(root)
    }
}
