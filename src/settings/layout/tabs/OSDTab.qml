pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.service
import qs.settings
import qs.settings.layout.components
import qs.config

Flickable {
    id: root

    readonly property var allOsds: ["Sink", "Source"]
    readonly property var labels: ({
            "Sink": "Output Volume",
            "Source": "Input Volume"
        })

    function disable(id) {
        var arr = Array.from(SettingsService.adapter.osd.active);
        var idx = arr.indexOf(id);
        if (idx !== -1) {
            arr.splice(idx, 1);
            SettingsService.setOsd(arr);
        }
    }
    function enable(id) {
        var arr = Array.from(SettingsService.adapter.osd.active);
        if (arr.indexOf(id) === -1) {
            arr.push(id);
            SettingsService.setOsd(arr);
        }
    }

    clip: true
    contentHeight: col.implicitHeight

    Column {
        id: col

        spacing: SettingsConfig.tabColumnSpacing
        width: root.width

        SettingsGroup {
            contentSpacing: SettingsConfig.groupContentSpacingSm
            flat: true
            title: "On-Screen Display"
            width: col.width

            Repeater {
                model: root.allOsds

                delegate: Rectangle {
                    id: row

                    required property string modelData
                    readonly property bool on: SettingsService.adapter.osd.active.indexOf(row.modelData) !== -1

                    border.color: ColorConfig.textAlpha07
                    border.width: SettingsConfig.hairlineBorderWidth
                    color: ColorConfig.textAlpha04
                    height: SettingsConfig.toggleTileHeight
                    radius: SettingsConfig.tileRadius
                    width: parent.width

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: SettingsConfig.tileContentMargin
                        anchors.verticalCenter: parent.verticalCenter
                        color: ColorConfig.text
                        font.family: FontConfig.fontFamily
                        font.pixelSize: FontConfig.fontSettingsBody
                        text: root.labels[row.modelData] ?? row.modelData
                    }
                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: SettingsConfig.tileContentMargin
                        anchors.verticalCenter: parent.verticalCenter
                        color: row.on ? ColorConfig.accent : ColorConfig.textAlpha15
                        height: SettingsConfig.toggleTrackHeight
                        radius: SettingsConfig.toggleTrackRadius
                        width: SettingsConfig.toggleTrackWidth

                        Behavior on color {
                            ColorAnimation {
                                duration: SettingsConfig.toggleAnimMs
                            }
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            color: "white"
                            height: SettingsConfig.toggleKnobSize
                            radius: SettingsConfig.toggleKnobRadius
                            width: SettingsConfig.toggleKnobSize
                            x: row.on ? parent.width - width - SettingsConfig.toggleKnobInset : SettingsConfig.toggleKnobInset

                            Behavior on x {
                                NumberAnimation {
                                    duration: SettingsConfig.toggleAnimMs
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onClicked: row.on ? root.disable(row.modelData) : root.enable(row.modelData)
                        }
                    }
                }
            }
        }
    }
}
