pragma ComponentBehavior: Bound

import QtQuick

import qs.components
import qs.service
import qs.controlcenter
import qs.controlcenter.layout
import qs.config

ControlCenterCard {
    cardKey: "volume"
    contentHeight: column.implicitHeight
    title: "Volume"

    Column {
        id: column

        spacing: ControlCenterConfig.volumeCardSpacing

        anchors {
            left: parent.left
            right: parent.right
        }
        VolumeRow {
            device: VolumeService.sink ? (VolumeService.sink.description || VolumeService.sink.name || "") : ""
            icon: VolumeService.sinkMuted ? IconConfig.volumeMute : VolumeService.sinkVolume === 0 ? IconConfig.volumeEmpty : VolumeService.sinkVolume < 0.5 ? IconConfig.volumeLow : IconConfig.volumeHigh
            label: "Output"
            muted: VolumeService.sinkMuted
            volume: VolumeService.sinkVolume
            width: parent.width

            onMuteToggled: VolumeService.setSinkMuted(!VolumeService.sinkMuted)
            onScrubbed: v => VolumeService.setSinkVolume(v)
        }
        VolumeRow {
            device: VolumeService.source ? (VolumeService.source.description || VolumeService.source.name || "") : ""
            icon: VolumeService.sourceMuted ? IconConfig.micOff : IconConfig.micOn
            label: "Input"
            muted: VolumeService.sourceMuted
            volume: VolumeService.sourceVolume
            width: parent.width

            onMuteToggled: VolumeService.setSourceMuted(!VolumeService.sourceMuted)
            onScrubbed: v => VolumeService.setSourceVolume(v)
        }
    }

    component VolumeRow: Column {
        id: row

        property string device: ""
        property string icon: ""
        property string label: ""
        property bool muted: false
        property real volume: 0

        signal muteToggled
        signal scrubbed(real value)

        spacing: ControlCenterConfig.volumeRowSpacing

        Row {
            spacing: ControlCenterConfig.volumeLabelRowSpacing
            width: parent.width

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: ColorConfig.text
                font.bold: true
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontBody
                text: row.label
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: ColorConfig.textDim
                elide: Text.ElideRight
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontBody
                text: row.device ? " — " + row.device : ""
                width: Math.min(implicitWidth, ControlCenterConfig.volumeDeviceTextMaxWidth)
            }
        }
        Item {
            height: ControlCenterConfig.volumeSliderRowHeight
            width: parent.width

            SliderBar {
                dimmed: row.muted
                height: ControlCenterConfig.volumeSliderHeight
                maxValue: 100
                value: row.muted ? 0 : row.volume * 100

                onScrubbed: v => row.scrubbed(v / 100)

                anchors {
                    left: parent.left
                    right: pct.left
                    rightMargin: ControlCenterConfig.volumeSliderPctGap
                    verticalCenter: parent.verticalCenter
                }
            }
            Text {
                id: pct

                color: ColorConfig.textDim
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontBody
                horizontalAlignment: Text.AlignRight
                text: row.muted ? "muted" : Math.round(row.volume * 100) + "%"
                width: ControlCenterConfig.volumePctTextWidth

                anchors {
                    right: muteBtn.left
                    rightMargin: ControlCenterConfig.volumePctMuteGap
                    verticalCenter: parent.verticalCenter
                }
            }
            Rectangle {
                id: muteBtn

                color: muteMa.containsMouse ? ColorConfig.overlay : ColorConfig.overlay
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
                    text: row.icon
                }
                MouseArea {
                    id: muteMa

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: row.muteToggled()
                }
            }
        }
    }
}
