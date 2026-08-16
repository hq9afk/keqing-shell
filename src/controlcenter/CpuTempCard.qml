pragma ComponentBehavior: Bound

import QtQuick

import qs.service
import qs.config

Item {
    id: root

    property int _coreCount: 0
    readonly property bool _hasCores: _coreCount > 0
    readonly property int _rows: Math.ceil(_coreCount / 2)

    clip: true
    height: cpuTempCardRect.height
    visible: height > 0
    width: parent.width

    Behavior on height {
        NumberAnimation {
            duration: GlobalConfig.animationNormal
            easing.type: Easing.OutCubic
        }
    }

    Component.onCompleted: {
        var vals = SystemStatService.intelTempValues;
        if (vals && vals.length > 0) {
            root._coreCount = vals.length;
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
    Rectangle {
        id: cpuTempCardRect

        readonly property real cpuTempContentHeight: ControlCenterConfig.tempRowHeight + (root._hasCores ? ControlCenterConfig.cpuTempGridTopMargin + root._rows * ControlCenterConfig.cpuCoreItemHeight + Math.max(0, root._rows - 1) * ControlCenterConfig.cpuCoreRowSpacing : 0)

        border.color: ColorConfig.accent
        border.width: ControlCenterConfig.cardBorderWidth
        color: ColorConfig.overlay
        height: ControlCenterConfig.cardTopPadding + cpuTempHdr.height + ControlCenterConfig.cardHeaderContentGap + cpuTempContentHeight + ControlCenterConfig.cardBottomPadding
        radius: ControlCenterConfig.cardRadius
        width: parent.width

        Item {
            id: cpuTempHdr

            height: ControlCenterConfig.cardHeaderHeight
            y: ControlCenterConfig.cardTopPadding

            anchors {
                left: parent.left
                leftMargin: ControlCenterConfig.cardHorizontalPadding
                right: parent.right
                rightMargin: ControlCenterConfig.cardHorizontalPadding
            }
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: ColorConfig.text
                font.bold: true
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontBody
                text: "CPU Temperature"
            }
        }
        Item {
            id: cpuTempContentArea

            height: cpuTempCardRect.cpuTempContentHeight

            anchors {
                left: parent.left
                leftMargin: ControlCenterConfig.cardHorizontalPadding
                right: parent.right
                rightMargin: ControlCenterConfig.cardHorizontalPadding
                top: cpuTempHdr.bottom
                topMargin: ControlCenterConfig.cardHeaderContentGap
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
    }
}
