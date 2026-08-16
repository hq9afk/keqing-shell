pragma ComponentBehavior: Bound

import QtQuick

import qs.elements
import qs.service
import qs.config

Item {
    id: root

    clip: true
    height: volumeCardRect.height
    visible: height > 0
    width: parent.width

    Behavior on height {
        NumberAnimation {
            duration: GlobalConfig.animationNormal
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: volumeCardRect

        border.color: ColorConfig.accent
        border.width: ControlCenterConfig.cardBorderWidth
        color: ColorConfig.overlay
        height: ControlCenterConfig.cardTopPadding + volumeHdr.height + ControlCenterConfig.cardHeaderContentGap + volumeColumn.implicitHeight + ControlCenterConfig.cardBottomPadding
        radius: ControlCenterConfig.cardRadius
        width: parent.width

        Item {
            id: volumeHdr

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
                text: "Volume"
            }
        }
        Item {
            id: volumeContentArea

            height: volumeColumn.implicitHeight

            anchors {
                left: parent.left
                leftMargin: ControlCenterConfig.cardHorizontalPadding
                right: parent.right
                rightMargin: ControlCenterConfig.cardHorizontalPadding
                top: volumeHdr.bottom
                topMargin: ControlCenterConfig.cardHeaderContentGap
            }
            Column {
                id: volumeColumn

                spacing: ControlCenterConfig.volumeCardSpacing

                anchors {
                    left: parent.left
                    right: parent.right
                }

                // Output
                Column {
                    id: outputRow

                    spacing: ControlCenterConfig.volumeRowSpacing
                    width: parent.width

                    Row {
                        spacing: ControlCenterConfig.volumeLabelRowSpacing
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
                            text: {
                                var d = VolumeService.sink ? (VolumeService.sink.description || VolumeService.sink.name || "") : "";
                                return d ? " — " + d : "";
                            }
                            width: Math.min(implicitWidth, ControlCenterConfig.volumeDeviceTextMaxWidth)
                        }
                    }
                    Item {
                        height: ControlCenterConfig.volumeSliderRowHeight
                        width: parent.width

                        SliderBar {
                            dimmed: VolumeService.sinkMuted
                            height: ControlCenterConfig.volumeSliderHeight
                            maxValue: 100
                            value: VolumeService.sinkMuted ? 0 : VolumeService.sinkVolume * 100

                            onScrubbed: v => VolumeService.setSinkVolume(v / 100)

                            anchors {
                                left: parent.left
                                right: outputPct.left
                                rightMargin: ControlCenterConfig.volumeSliderPctGap
                                verticalCenter: parent.verticalCenter
                            }
                        }
                        Text {
                            id: outputPct

                            color: ColorConfig.textDim
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontBody
                            horizontalAlignment: Text.AlignRight
                            text: VolumeService.sinkMuted ? "muted" : Math.round(VolumeService.sinkVolume * 100) + "%"
                            width: ControlCenterConfig.volumePctTextWidth

                            anchors {
                                right: outputMuteBtn.left
                                rightMargin: ControlCenterConfig.volumePctMuteGap
                                verticalCenter: parent.verticalCenter
                            }
                        }
                        Rectangle {
                            id: outputMuteBtn

                            color: outputMuteMa.containsMouse ? ColorConfig.overlay : ColorConfig.overlay
                            height: ControlCenterConfig.volumeMuteBtnSize
                            radius: ControlCenterConfig.volumeMuteBtnRadius
                            width: ControlCenterConfig.volumeMuteBtnSize

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
                                id: outputMuteMa

                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                onClicked: VolumeService.setSinkMuted(!VolumeService.sinkMuted)
                            }
                        }
                    }
                }

                // Input
                Column {
                    id: inputRow

                    spacing: ControlCenterConfig.volumeRowSpacing
                    width: parent.width

                    Row {
                        spacing: ControlCenterConfig.volumeLabelRowSpacing
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
                            text: {
                                var d = VolumeService.source ? (VolumeService.source.description || VolumeService.source.name || "") : "";
                                return d ? " — " + d : "";
                            }
                            width: Math.min(implicitWidth, ControlCenterConfig.volumeDeviceTextMaxWidth)
                        }
                    }
                    Item {
                        height: ControlCenterConfig.volumeSliderRowHeight
                        width: parent.width

                        SliderBar {
                            dimmed: VolumeService.sourceMuted
                            height: ControlCenterConfig.volumeSliderHeight
                            maxValue: 100
                            value: VolumeService.sourceMuted ? 0 : VolumeService.sourceVolume * 100

                            onScrubbed: v => VolumeService.setSourceVolume(v / 100)

                            anchors {
                                left: parent.left
                                right: inputPct.left
                                rightMargin: ControlCenterConfig.volumeSliderPctGap
                                verticalCenter: parent.verticalCenter
                            }
                        }
                        Text {
                            id: inputPct

                            color: ColorConfig.textDim
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontBody
                            horizontalAlignment: Text.AlignRight
                            text: VolumeService.sourceMuted ? "muted" : Math.round(VolumeService.sourceVolume * 100) + "%"
                            width: ControlCenterConfig.volumePctTextWidth

                            anchors {
                                right: inputMuteBtn.left
                                rightMargin: ControlCenterConfig.volumePctMuteGap
                                verticalCenter: parent.verticalCenter
                            }
                        }
                        Rectangle {
                            id: inputMuteBtn

                            color: inputMuteMa.containsMouse ? ColorConfig.overlay : ColorConfig.overlay
                            height: ControlCenterConfig.volumeMuteBtnSize
                            radius: ControlCenterConfig.volumeMuteBtnRadius
                            width: ControlCenterConfig.volumeMuteBtnSize

                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            Text {
                                anchors.centerIn: parent
                                color: ColorConfig.text
                                font.family: IconConfig.fontFamily
                                font.pixelSize: FontConfig.fontPanelActionIcon
                                text: VolumeService.sourceMuted ? IconConfig.micOff : IconConfig.micOn
                            }
                            MouseArea {
                                id: inputMuteMa

                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                onClicked: VolumeService.setSourceMuted(!VolumeService.sourceMuted)
                            }
                        }
                    }
                }
            }
        }
    }
}
