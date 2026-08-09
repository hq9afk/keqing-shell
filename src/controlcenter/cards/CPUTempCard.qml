pragma ComponentBehavior: Bound

import QtQuick

import qs.service
import qs.controlcenter
import qs.controlcenter.layout
import qs.config

ControlCenterCard {
    id: root

    property int _coreCount: 0
    readonly property bool _hasCores: _coreCount > 0
    readonly property int _rows: Math.ceil(_coreCount / 2)

    cardKey: "cpuTemp"
    contentHeight: ControlCenterConfig.tempRowHeight + (_hasCores ? ControlCenterConfig.cpuTempGridTopMargin + _rows * ControlCenterConfig.cpuCoreItemHeight + Math.max(0, _rows - 1) * ControlCenterConfig.cpuCoreRowSpacing : 0)
    title: "CPU Temperature"

    Component.onCompleted: {
        var vals = SystemStatService.intelTempValues;
        if (vals && vals.length > 0) {
            _coreCount = vals.length;
            for (var i = 0; i < vals.length; i++)
                coreModel.append({
                    temp: vals[i]
                });
        }
    }

    ListModel {
        id: coreModel
    }
    Connections {
        function onIntelTempValuesChanged() {
            var vals = SystemStatService.intelTempValues;
            if (!vals || vals.length === 0)
                return;
            if (coreModel.count === 0) {
                root._coreCount = vals.length;
                for (var i = 0; i < vals.length; i++)
                    coreModel.append({
                        temp: vals[i]
                    });
            } else {
                for (var i = 0; i < Math.min(vals.length, coreModel.count); i++)
                    coreModel.setProperty(i, "temp", vals[i]);
            }
        }

        target: SystemStatService
    }
    Text {
        id: avgTemp

        color: {
            var t = SystemStatService.cpuTempC;
            if (t >= 85)
                return "#ef4444";
            if (t >= 70)
                return "#f97316";
            return ColorConfig.text;
        }
        font.bold: true
        font.family: FontConfig.fontFamily
        font.pixelSize: FontConfig.fontTempValue
        text: SystemStatService.cpuTempC + " °C"

        anchors {
            left: parent.left
            right: parent.right
        }
    }
    Grid {
        id: coreGrid

        columnSpacing: ControlCenterConfig.cpuCoreColumnSpacing
        columns: ControlCenterConfig.cpuCoreColumns
        rowSpacing: ControlCenterConfig.cpuCoreRowSpacing
        visible: root._hasCores

        anchors {
            left: parent.left
            right: parent.right
            top: avgTemp.bottom
            topMargin: ControlCenterConfig.cpuTempGridTopMargin
        }
        Repeater {
            model: coreModel

            Rectangle {
                id: coreItem

                required property int index
                required property real temp

                color: ColorConfig.textAlpha08
                height: ControlCenterConfig.cpuCoreItemHeight
                radius: ControlCenterConfig.cpuCoreItemRadius
                width: (coreGrid.width - coreGrid.columnSpacing) / ControlCenterConfig.cpuCoreColumns

                Text {
                    color: ColorConfig.textDim
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody - 1
                    text: "Core " + coreItem.index

                    anchors {
                        left: parent.left
                        leftMargin: ControlCenterConfig.cpuCoreTextMargin
                        verticalCenter: parent.verticalCenter
                    }
                }
                Text {
                    color: {
                        if (coreItem.temp >= 85)
                            return "#ef4444";
                        if (coreItem.temp >= 70)
                            return "#f97316";
                        return ColorConfig.text;
                    }
                    font.bold: true
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody - 1
                    text: Math.round(coreItem.temp) + " °C"

                    anchors {
                        right: parent.right
                        rightMargin: ControlCenterConfig.cpuCoreTextMargin
                        verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }
}
