pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.elements
import qs.service
import qs.settings
import qs.config

Item {
    id: root

    readonly property bool overrideEnabled: {
        if (root.selectedScreen === "default")
            return true;
        var entry = SettingsService.displays[root.selectedScreen];
        return entry !== undefined && entry._enabled !== false;
    }
    property string selectedScreen: "default"
    readonly property var sortedScreens: {
        var screens = [];
        for (var i = 0; i < Quickshell.screens.length; i++)
            screens.push(Quickshell.screens[i]);
        screens.sort((a, b) => a.name < b.name ? -1 : a.name > b.name ? 1 : 0);
        return screens;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: SettingsConfig.tabColumnSpacing

        Row {
            id: screenRow

            Layout.fillWidth: true
            spacing: SettingsConfig.screenSelectorSpacing

            Rectangle {
                border.color: root.selectedScreen === "default" ? ColorConfig.accentAlt : "transparent"
                border.width: SettingsConfig.selectorBorderWidth
                color: ColorConfig.lavenderAlpha20
                height: SettingsConfig.screenSelectorHeight
                radius: SettingsConfig.tileRadius
                width: (screenRow.width - root.sortedScreens.length * screenRow.spacing) / Math.max(1, root.sortedScreens.length + 1)

                Behavior on border.color {
                    ColorAnimation {
                        duration: SettingsConfig.quickColorAnimMs
                    }
                }

                Text {
                    anchors.centerIn: parent
                    color: ColorConfig.text
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontSettingsBody
                    text: "Default"
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor

                    onClicked: root.selectedScreen = "default"
                }
            }
            Repeater {
                model: root.sortedScreens

                delegate: Rectangle {
                    required property var modelData

                    border.color: root.selectedScreen === modelData.name ? ColorConfig.accentAlt : "transparent"
                    border.width: SettingsConfig.selectorBorderWidth
                    color: ColorConfig.lavenderAlpha20
                    height: SettingsConfig.screenSelectorHeight
                    radius: SettingsConfig.tileRadius
                    width: (screenRow.width - root.sortedScreens.length * screenRow.spacing) / Math.max(1, root.sortedScreens.length + 1)

                    Behavior on border.color {
                        ColorAnimation {
                            duration: SettingsConfig.quickColorAnimMs
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        color: ColorConfig.text
                        font.family: FontConfig.fontFamily
                        font.pixelSize: FontConfig.fontSettingsBody
                        text: modelData.name
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: root.selectedScreen = parent.modelData.name
                    }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            visible: root.selectedScreen !== "default"

            Text {
                Layout.fillWidth: true
                color: ColorConfig.text
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontSettingsBody
                opacity: SettingsConfig.labelOpacity
                text: "Override default settings"
            }
            Toggle {
                active: root.overrideEnabled

                onToggled: {
                    var enabled = !root.overrideEnabled;
                    SettingsService.setDisplayOverrideEnabled(root.selectedScreen, enabled);
                    SettingsService.setBarOverrideEnabled(root.selectedScreen, enabled);
                }
            }
        }
        Column {
            Layout.fillWidth: true
            spacing: SettingsConfig.groupContentSpacingSm
            visible: root.overrideEnabled

            Repeater {
                model: [
                    {
                        label: "Dock",
                        key: "dock"
                    },
                    {
                        label: "OSD",
                        key: "osd"
                    },
                    {
                        label: "Notifications",
                        key: "notifications"
                    },
                    {
                        label: "Lock",
                        key: "lock"
                    }
                ]

                delegate: Rectangle {
                    id: toggleTile

                    required property int index
                    required property var modelData

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
                            text: toggleTile.modelData.label
                        }
                        Toggle {
                            active: SettingsService.displayValue(root.selectedScreen, toggleTile.modelData.key)

                            onToggled: SettingsService.setDisplayValue(root.selectedScreen, toggleTile.modelData.key, !active)
                        }
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
                        text: "Bar Autohide"
                    }
                    Toggle {
                        active: SettingsService.barValue(root.selectedScreen, "autohideEnabled")

                        onToggled: SettingsService.setBarValue(root.selectedScreen, "autohideEnabled", !active)
                    }
                }
            }
        }
        Item {
            Layout.fillHeight: true
        }
    }
}
