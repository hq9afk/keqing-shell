pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.UPower

import qs.service
import qs.controlcenter
import qs.controlcenter.layout
import qs.config

ControlCenterCard {
    id: root

    function formatTime(seconds) {
        if (!seconds || seconds <= 0)
            return "";
        var h = Math.floor(seconds / 3600);
        var m = Math.floor((seconds % 3600) / 60);
        return h + " h " + m + " min";
    }

    cardKey: "battery"
    contentHeight: batRow.height
    gated: !BatteryService.detected
    title: "Battery"

    Column {
        id: batRow

        spacing: ControlCenterConfig.batteryRowSpacing

        anchors {
            left: parent.left
            right: parent.right
        }
        Row {
            spacing: ControlCenterConfig.batteryHeaderSpacing
            width: parent.width

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: {
                    if (BatteryService.charging || BatteryService.allFull)
                        return ColorConfig.accent;
                    if (BatteryService.pct <= 15)
                        return "#F44747";
                    if (BatteryService.pct <= 30)
                        return "#E0A83A";
                    return ColorConfig.text;
                }
                font.family: IconConfig.fontFamily
                font.pixelSize: FontConfig.fontCardIcon
                text: {
                    if (BatteryService.charging || BatteryService.allFull)
                        return IconConfig.batteryCharging;
                    if (BatteryService.pct > 75)
                        return IconConfig.battery4;
                    if (BatteryService.pct > 50)
                        return IconConfig.battery3;
                    if (BatteryService.pct > 25)
                        return IconConfig.battery2;
                    return IconConfig.battery1;
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: ControlCenterConfig.batteryTextSpacing

                Text {
                    color: ColorConfig.text
                    font.bold: true
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody + 1
                    text: "Battery " + BatteryService.pct + "%"
                }
                Text {
                    color: ColorConfig.textDim
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody - 1
                    text: {
                        if (BatteryService.allFull)
                            return "Full";
                        if (BatteryService.charging && BatteryService.battery) {
                            var t = root.formatTime(BatteryService.battery.timeToFull);
                            return t !== "" ? t + " to full" : "Charging";
                        }
                        if (BatteryService.battery) {
                            var te = root.formatTime(BatteryService.battery.timeToEmpty);
                            return te !== "" ? te + " remaining" : "Discharging";
                        }
                        return "";
                    }
                }
            }
        }
        Rectangle {
            color: ColorConfig.textAlpha10
            height: ControlCenterConfig.batteryBarHeight
            radius: ControlCenterConfig.batteryBarRadius
            width: parent.width

            Rectangle {
                color: {
                    if (BatteryService.charging || BatteryService.allFull)
                        return ColorConfig.accent;
                    if (BatteryService.pct <= 15)
                        return "#F44747";
                    if (BatteryService.pct <= 30)
                        return "#E0A83A";
                    return ColorConfig.accent;
                }
                height: parent.height
                radius: parent.radius
                width: Math.max(radius * 2, parent.width * Math.min(BatteryService.pct, 100) / 100)

                Behavior on color {
                    ColorAnimation {
                        duration: ControlCenterConfig.batteryColorAnimMs
                    }
                }
                Behavior on width {
                    NumberAnimation {
                        duration: ControlCenterConfig.batteryWidthAnimMs
                    }
                }
            }
        }
    }
}
