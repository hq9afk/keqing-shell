pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.components
import qs.service
import qs.settings
import qs.settings.layout.components
import qs.config

Flickable {
    id: root

    readonly property bool overrideEnabled: {
        if (selectedScreen === "default")
            return true;
        var entry = SettingsService.barDisplays[selectedScreen];
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

    function setOverrideEnabled(enabled) {
        SettingsService.setBarOverrideEnabled(root.selectedScreen, enabled);
        SettingsService.setWidgetOverrideEnabled(root.selectedScreen, enabled);
    }

    clip: true
    contentHeight: col.implicitHeight

    Column {
        id: col

        spacing: SettingsConfig.tabColumnSpacing
        width: root.width

        Row {
            id: screenSelectorRow

            spacing: SettingsConfig.screenSelectorSpacing
            width: parent.width

            Rectangle {
                border.color: root.selectedScreen === "default" ? ColorConfig.accentAlt : "transparent"
                border.width: SettingsConfig.selectorBorderWidth
                color: ColorConfig.lavenderAlpha20
                height: SettingsConfig.screenSelectorHeight
                radius: SettingsConfig.tileRadius
                width: (screenSelectorRow.width - root.sortedScreens.length * screenSelectorRow.spacing) / Math.max(1, root.sortedScreens.length + 1)

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
                    width: (screenSelectorRow.width - root.sortedScreens.length * screenSelectorRow.spacing) / Math.max(1, root.sortedScreens.length + 1)

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
            visible: root.selectedScreen !== "default"
            width: parent.width

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

                onToggled: root.setOverrideEnabled(!root.overrideEnabled)
            }
        }
        SettingsGroup {
            title: "Behavior"
            visible: root.overrideEnabled
            width: col.width

            RowLayout {
                width: parent.width

                Text {
                    Layout.fillWidth: true
                    color: ColorConfig.text
                    font.family: FontConfig.fontFamily
                    font.pixelSize: FontConfig.fontSettingsBody
                    opacity: SettingsConfig.labelOpacity
                    text: "Autohide"
                }
                Toggle {
                    active: SettingsService.barValue(root.selectedScreen, "autohideEnabled")

                    onToggled: SettingsService.setBarValue(root.selectedScreen, "autohideEnabled", !active)
                }
            }
        }
        SettingsGroup {
            contentSpacing: SettingsConfig.groupContentSpacingLg
            title: "Widgets"
            visible: root.overrideEnabled
            width: col.width

            WidgetRow {
                screenName: root.selectedScreen
                section: "left"
                width: parent.width
            }
            WidgetRow {
                screenName: root.selectedScreen
                section: "center"
                width: parent.width
            }
            WidgetRow {
                screenName: root.selectedScreen
                section: "right"
                width: parent.width
            }
        }
        Item {
            height: SettingsConfig.tabBottomSpacerHeight
        }
    }
}
