pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.elements
import qs.service
import qs.modules.bar.components
import qs.config

WidgetPanel {
    id: root

    clip: true
    implicitHeight: Math.min(500, flickable.contentHeight + BarConfig.panelPadding * 2)
    implicitWidth: BarConfig.panelWidthSmall

    MouseArea {
        anchors.fill: parent
    }
    Flickable {
        id: flickable

        clip: true
        contentHeight: col.implicitHeight

        anchors {
            fill: parent
            margins: BarConfig.panelPadding
        }
        Column {
            id: col

            spacing: 0
            width: flickable.width

            Item {
                height: BarConfig.panelHeaderHeight
                width: parent.width

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: ColorConfig.text
                    font.bold: true
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody + 1
                    text: "Volume"
                }
                Rectangle {
                    id: closeBtn

                    color: closeMa.containsMouse ? ColorConfig.overlay : ColorConfig.overlay
                    height: BarConfig.panelCloseButtonSize
                    radius: BarConfig.panelCloseButtonRadius
                    width: BarConfig.panelCloseButtonSize

                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    Text {
                        anchors.centerIn: parent
                        color: ColorConfig.text
                        font.family: IconConfig.fontFamily
                        font.pixelSize: FontConfig.fontPanelActionIcon
                        text: IconConfig.close
                    }
                    MouseArea {
                        id: closeMa

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: PanelService.closePanel()
                    }
                }
            }
            Divider {
                width: parent.width
            }
            Item {
                height: BarConfig.panelSectionGap
                width: parent.width
            }
            Row {
                spacing: BarConfig.panelTightGap
                width: parent.width

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: ColorConfig.text
                    font.bold: true
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody
                    text: "Output"
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: ColorConfig.textDim
                    elide: Text.ElideRight
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody
                    text: VolumeService.sink ? " — " + (VolumeService.sink.description || VolumeService.sink.name || "") : ""
                    width: Math.min(implicitWidth, BarConfig.volumeLabelWidthCap)
                }
            }
            Item {
                height: BarConfig.panelRowGap
                width: parent.width
            }
            Item {
                id: outputRow

                height: BarConfig.volumeRowHeight
                width: parent.width

                SliderBar {
                    id: outSlider

                    dimmed: VolumeService.sinkMuted
                    height: BarConfig.volumeSliderHeight
                    maxValue: 100
                    value: VolumeService.sinkMuted ? 0 : VolumeService.sinkVolume * 100

                    onScrubbed: v => VolumeService.setSinkVolume(v / 100)

                    anchors {
                        left: parent.left
                        right: outPct.left
                        rightMargin: BarConfig.volumeSliderRightGap
                        verticalCenter: parent.verticalCenter
                    }
                }
                Text {
                    id: outPct

                    color: ColorConfig.textDim
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody
                    horizontalAlignment: Text.AlignRight
                    text: VolumeService.sinkMuted ? "muted" : Math.round(VolumeService.sinkVolume * 100) + "%"
                    width: BarConfig.volumePercentLabelWidth

                    anchors {
                        right: outMuteBtn.left
                        rightMargin: BarConfig.panelRowGap
                        verticalCenter: parent.verticalCenter
                    }
                }
                Rectangle {
                    id: outMuteBtn

                    color: outMuteMa.containsMouse ? ColorConfig.overlay : ColorConfig.overlay
                    height: BarConfig.panelActionButtonSize
                    radius: BarConfig.panelActionButtonRadius
                    width: BarConfig.panelActionButtonSize

                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    Text {
                        anchors.centerIn: parent
                        color: ColorConfig.text
                        font.family: IconConfig.fontFamily
                        font.pixelSize: FontConfig.fontPanelActionIcon
                        text: VolumeService.sinkMuted ? IconConfig.volumeMute : VolumeService.sinkVolume === 0 ? IconConfig.volumeEmpty : VolumeService.sinkVolume < 0.5 ? IconConfig.volumeLow : IconConfig.volumeHigh
                    }
                    MouseArea {
                        id: outMuteMa

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: VolumeService.setSinkMuted(!VolumeService.sinkMuted)
                    }
                }
            }
            Item {
                height: BarConfig.panelSectionGap
                width: parent.width
            }
            Row {
                spacing: BarConfig.panelTightGap
                width: parent.width

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: ColorConfig.text
                    font.bold: true
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody
                    text: "Input"
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    color: ColorConfig.textDim
                    elide: Text.ElideRight
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody
                    text: VolumeService.source ? " — " + (VolumeService.source.description || VolumeService.source.name || "") : ""
                    width: Math.min(implicitWidth, BarConfig.volumeLabelWidthCap)
                }
            }
            Item {
                height: BarConfig.panelRowGap
                width: parent.width
            }
            Item {
                id: inputRow

                height: BarConfig.volumeRowHeight
                width: parent.width

                SliderBar {
                    dimmed: VolumeService.sourceMuted
                    height: BarConfig.volumeSliderHeight
                    maxValue: 100
                    value: VolumeService.sourceMuted ? 0 : VolumeService.sourceVolume * 100

                    onScrubbed: v => VolumeService.setSourceVolume(v / 100)

                    anchors {
                        left: parent.left
                        right: inPct.left
                        rightMargin: BarConfig.volumeSliderRightGap
                        verticalCenter: parent.verticalCenter
                    }
                }
                Text {
                    id: inPct

                    color: ColorConfig.textDim
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontBody
                    horizontalAlignment: Text.AlignRight
                    text: VolumeService.sourceMuted ? "muted" : Math.round(VolumeService.sourceVolume * 100) + "%"
                    width: BarConfig.volumePercentLabelWidth

                    anchors {
                        right: inMuteBtn.left
                        rightMargin: BarConfig.panelRowGap
                        verticalCenter: parent.verticalCenter
                    }
                }
                Rectangle {
                    id: inMuteBtn

                    color: inMuteMa.containsMouse ? ColorConfig.overlay : ColorConfig.overlay
                    height: BarConfig.panelActionButtonSize
                    radius: BarConfig.panelActionButtonRadius
                    width: BarConfig.panelActionButtonSize

                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    Text {
                        anchors.centerIn: parent
                        color: ColorConfig.text
                        font.family: IconConfig.fontFamily
                        font.pixelSize: FontConfig.fontPanelActionIcon
                        text: VolumeService.sourceMuted ? IconConfig.volumeMute : VolumeService.sourceVolume === 0 ? IconConfig.volumeEmpty : VolumeService.sourceVolume < 0.5 ? IconConfig.volumeLow : IconConfig.volumeHigh
                    }
                    MouseArea {
                        id: inMuteMa

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: VolumeService.setSourceMuted(!VolumeService.sourceMuted)
                    }
                }
            }
            Item {
                height: BarConfig.panelSectionGap
                width: parent.width
            }
            Divider {
                width: parent.width
            }
            Item {
                height: BarConfig.panelContentGap
                width: parent.width
            }
            Text {
                color: ColorConfig.text
                font.bold: true
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontBody
                height: implicitHeight + BarConfig.volumeSectionHeaderPad
                text: "Applications"
            }
            Repeater {
                model: VolumeService.nodes

                Item {
                    id: appItem

                    readonly property bool isPlayback: {
                        var props = modelData?.properties;
                        if (!props)
                            return false;
                        if ((props["media.class"] || "") !== "Stream/Output/Audio")
                            return false;
                        if (props["stream.capture.sink"] !== undefined)
                            return false;
                        return true;
                    }
                    required property var modelData

                    height: visible ? appRowItem.implicitHeight + BarConfig.volumeAppRowBottomPad : 0
                    visible: isPlayback
                    width: col.width

                    Item {
                        id: appRowItem

                        implicitHeight: appNameTxt.implicitHeight + appSlider.implicitHeight + BarConfig.volumeAppListTopGap

                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        Text {
                            id: appNameTxt

                            color: ColorConfig.text
                            elide: Text.ElideRight
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontBody
                            text: {
                                var props = appItem.modelData?.properties;
                                if (props) {
                                    var n = props["application.name"] || "";
                                    if (n)
                                        return n;
                                }
                                return appItem.modelData?.description || appItem.modelData?.name || "Unknown";
                            }

                            anchors {
                                left: parent.left
                                right: appPctTxt.left
                                rightMargin: BarConfig.panelRowGap
                            }
                        }
                        Text {
                            id: appPctTxt

                            color: ColorConfig.textDim
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontBody
                            horizontalAlignment: Text.AlignRight
                            text: {
                                var a = appItem.modelData?.audio;
                                if (!a)
                                    return "—";
                                return a.muted ? "muted" : Math.round(a.volume * 100) + "%";
                            }
                            width: BarConfig.volumePercentLabelWidth

                            anchors {
                                right: appMuteRect.left
                                rightMargin: BarConfig.panelRowGap
                                top: appNameTxt.top
                            }
                        }
                        Rectangle {
                            id: appMuteRect

                            color: appMuteMa.containsMouse ? ColorConfig.overlay : ColorConfig.overlay
                            height: BarConfig.panelActionButtonSize
                            radius: BarConfig.panelActionButtonRadius
                            width: BarConfig.panelActionButtonSize

                            anchors {
                                right: parent.right
                                top: appNameTxt.top
                            }
                            Text {
                                anchors.centerIn: parent
                                color: ColorConfig.text
                                font.family: IconConfig.fontFamily
                                font.pixelSize: FontConfig.fontPanelActionIcon
                                text: {
                                    var a = appItem.modelData?.audio;
                                    var m = a?.muted ?? false;
                                    var v = a?.volume ?? 0;
                                    return m ? IconConfig.volumeMute : v === 0 ? IconConfig.volumeEmpty : v < 0.5 ? IconConfig.volumeLow : IconConfig.volumeHigh;
                                }
                            }
                            MouseArea {
                                id: appMuteMa

                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                onClicked: {
                                    var a = appItem.modelData?.audio;
                                    if (a)
                                        a.muted = !a.muted;
                                }
                            }
                        }
                        SliderBar {
                            id: appSlider

                            dimmed: appItem.modelData?.audio?.muted ?? false
                            height: BarConfig.volumeAppSliderHeight
                            maxValue: 100
                            value: (appItem.modelData?.audio?.volume ?? 0) * 100

                            onScrubbed: v => {
                                var a = appItem.modelData?.audio;
                                if (a) {
                                    a.volume = v / 100;
                                    if (v > 0)
                                        a.muted = false;
                                }
                            }

                            anchors {
                                left: parent.left
                                right: appPctTxt.left
                                rightMargin: BarConfig.panelRowGap
                                top: appNameTxt.bottom
                                topMargin: BarConfig.volumeAppListTopGap
                            }
                        }
                    }
                }
            }
            Item {
                height: BarConfig.panelContentGap
                width: parent.width
            }
            Divider {
                width: parent.width
            }
            Item {
                height: BarConfig.panelContentGap
                width: parent.width
            }
            Text {
                color: ColorConfig.text
                font.bold: true
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontBody
                height: implicitHeight + BarConfig.volumeSectionHeaderPad
                text: "Output Device"
            }
            Repeater {
                model: VolumeService.outputSinks

                Item {
                    id: sinkItem

                    readonly property bool isDefault: VolumeService.sink?.id === modelData.id
                    required property var modelData

                    height: sinkRow.implicitHeight + BarConfig.volumeDeviceRowBottomPad
                    width: col.width

                    Row {
                        id: sinkRow

                        anchors.verticalCenter: parent.verticalCenter
                        spacing: BarConfig.panelRowIconGap

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            color: sinkItem.isDefault ? ColorConfig.accent : ColorConfig.textAlpha20
                            height: BarConfig.volumeDeviceIndicatorSize
                            radius: BarConfig.volumeDeviceIndicatorRadius
                            width: BarConfig.volumeDeviceIndicatorSize

                            Rectangle {
                                anchors.centerIn: parent
                                color: "white"
                                height: BarConfig.volumeDeviceIndicatorDotSize
                                radius: BarConfig.volumeDeviceIndicatorDotRadius
                                visible: sinkItem.isDefault
                                width: BarConfig.volumeDeviceIndicatorDotSize
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            color: sinkItem.isDefault ? ColorConfig.accent : ColorConfig.text
                            elide: Text.ElideRight
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontBody
                            text: sinkItem.modelData.description || sinkItem.modelData.name || "Unknown"
                            width: col.width - BarConfig.panelActionButtonSize - BarConfig.panelRowIconGap
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: Quickshell.execDetached(["wpctl", "set-default", sinkItem.modelData.id.toString()])
                    }
                }
            }
            Item {
                height: BarConfig.panelContentGap
                width: parent.width
            }
            Text {
                color: ColorConfig.text
                font.bold: true
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontBody
                height: implicitHeight + BarConfig.volumeSectionHeaderPad
                text: "Input Device"
            }
            Repeater {
                model: VolumeService.inputSources

                Item {
                    id: sourceItem

                    readonly property bool isDefault: VolumeService.source?.id === modelData.id
                    required property var modelData

                    height: sourceRow.implicitHeight + BarConfig.volumeDeviceRowBottomPad
                    width: col.width

                    Row {
                        id: sourceRow

                        anchors.verticalCenter: parent.verticalCenter
                        spacing: BarConfig.panelRowIconGap

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            color: sourceItem.isDefault ? ColorConfig.accent : ColorConfig.textAlpha20
                            height: BarConfig.volumeDeviceIndicatorSize
                            radius: BarConfig.volumeDeviceIndicatorRadius
                            width: BarConfig.volumeDeviceIndicatorSize

                            Rectangle {
                                anchors.centerIn: parent
                                color: "white"
                                height: BarConfig.volumeDeviceIndicatorDotSize
                                radius: BarConfig.volumeDeviceIndicatorDotRadius
                                visible: sourceItem.isDefault
                                width: BarConfig.volumeDeviceIndicatorDotSize
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            color: sourceItem.isDefault ? ColorConfig.accent : ColorConfig.text
                            elide: Text.ElideRight
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontBody
                            text: sourceItem.modelData.description || sourceItem.modelData.name || "Unknown"
                            width: col.width - BarConfig.panelActionButtonSize - BarConfig.panelRowIconGap
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: Quickshell.execDetached(["wpctl", "set-default", sourceItem.modelData.id.toString()])
                    }
                }
            }
            Item {
                height: BarConfig.panelSectionGap
                width: parent.width
            }
        }
    }
}
