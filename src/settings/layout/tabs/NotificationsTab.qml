pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.service
import qs.settings
import qs.settings.layout.components
import qs.config

Flickable {
    id: root

    clip: true
    contentHeight: col.implicitHeight

    Column {
        id: col

        spacing: SettingsConfig.tabColumnSpacing
        width: root.width

        SettingsGroup {
            contentSpacing: SettingsConfig.groupContentSpacingSm
            flat: true
            title: "Position"
            width: col.width

            Rectangle {
                border.color: ColorConfig.textAlpha07
                border.width: SettingsConfig.hairlineBorderWidth
                color: ColorConfig.textAlpha04
                height: SettingsConfig.toggleTileHeight
                radius: SettingsConfig.tileRadius
                width: parent.width

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: SettingsConfig.tileContentMargin
                    anchors.rightMargin: SettingsConfig.tileContentMargin
                    spacing: SettingsConfig.tileContentSpacing

                    Text {
                        Layout.fillWidth: true
                        color: ColorConfig.text
                        font.family: FontConfig.fontFamily
                        font.pixelSize: FontConfig.fontSettingsBody
                        opacity: SettingsConfig.labelOpacity
                        text: "Vertical"
                    }
                    DropdownMenu {
                        activeValue: SettingsService.adapter.notification.vertical
                        labelRole: "label"
                        model: [
                            {
                                "label": "Top",
                                "value": "top"
                            },
                            {
                                "label": "Bottom",
                                "value": "bottom"
                            }
                        ]
                        valueRole: "value"

                        onItemSelected: value => SettingsService.setNotification({
                                vertical: value
                            })
                    }
                }
            }
            Rectangle {
                border.color: ColorConfig.textAlpha07
                border.width: SettingsConfig.hairlineBorderWidth
                color: ColorConfig.textAlpha04
                height: SettingsConfig.toggleTileHeight
                radius: SettingsConfig.tileRadius
                width: parent.width

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: SettingsConfig.tileContentMargin
                    anchors.rightMargin: SettingsConfig.tileContentMargin
                    spacing: SettingsConfig.tileContentSpacing

                    Text {
                        Layout.fillWidth: true
                        color: ColorConfig.text
                        font.family: FontConfig.fontFamily
                        font.pixelSize: FontConfig.fontSettingsBody
                        opacity: SettingsConfig.labelOpacity
                        text: "Horizontal"
                    }
                    DropdownMenu {
                        activeValue: SettingsService.adapter.notification.horizontal
                        labelRole: "label"
                        model: [
                            {
                                "label": "Left",
                                "value": "left"
                            },
                            {
                                "label": "Center",
                                "value": "center"
                            },
                            {
                                "label": "Right",
                                "value": "right"
                            }
                        ]
                        valueRole: "value"

                        onItemSelected: value => SettingsService.setNotification({
                                horizontal: value
                            })
                    }
                }
            }
        }
    }
}
