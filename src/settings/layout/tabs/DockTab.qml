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
        var entry = SettingsService.dockDisplays[selectedScreen];
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
        SettingsService.setDockOverrideEnabled(root.selectedScreen, enabled);
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
                    active: SettingsService.dockValue(root.selectedScreen, "autohideEnabled")

                    onToggled: SettingsService.setDockValue(root.selectedScreen, "autohideEnabled", !active)
                }
            }
        }
        SettingsGroup {
            contentSpacing: SettingsConfig.groupContentSpacingSm
            flat: true
            title: "Geometry"
            width: col.width

            Rectangle {
                id: marginTile

                function currentText() {
                    return Math.round(SettingsService.adapter.dock.marginBottom).toString();
                }

                border.color: ColorConfig.textAlpha07
                border.width: SettingsConfig.hairlineBorderWidth
                color: ColorConfig.textAlpha04
                height: SettingsConfig.numericTileHeight
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
                        font.weight: Font.DemiBold
                        opacity: SettingsConfig.labelOpacity
                        text: "Bottom Margin"
                    }
                    Rectangle {
                        border.color: marginInput.activeFocus ? ColorConfig.accent : ColorConfig.textAlpha15
                        border.width: SettingsConfig.hairlineBorderWidth
                        color: ColorConfig.textAlpha07
                        implicitHeight: SettingsConfig.numberFieldHeight
                        implicitWidth: SettingsConfig.numberFieldWidth
                        radius: SettingsConfig.fieldRadius

                        Behavior on border.color {
                            ColorAnimation {
                                duration: GlobalConfig.animationFast
                            }
                        }

                        TextInput {
                            id: marginInput

                            anchors.fill: parent
                            anchors.margins: SettingsConfig.textFieldInset
                            color: ColorConfig.text
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontSettingsBody
                            horizontalAlignment: TextInput.AlignHCenter
                            selectByMouse: true
                            text: marginTile.currentText()

                            onEditingFinished: {
                                var v = parseInt(text, 10);
                                if (!isNaN(v)) {
                                    v = Math.max(0, Math.min(80, v));
                                    SettingsService.adapter.dock.marginBottom = v;
                                    SettingsService.save();
                                }
                                marginInput.text = Qt.binding(marginTile.currentText);
                            }
                        }
                    }
                    Text {
                        color: ColorConfig.text
                        font.family: IconConfig.fontFamily
                        font.pixelSize: FontConfig.fontSettingsWindowIcon
                        opacity: resetMa.containsMouse ? SettingsConfig.iconHoverOpacity : SettingsConfig.faintOpacity
                        text: IconConfig.refresh

                        Behavior on opacity {
                            NumberAnimation {
                                duration: GlobalConfig.animationFast
                            }
                        }

                        MouseArea {
                            id: resetMa

                            anchors.fill: parent
                            anchors.margins: SettingsConfig.iconHoverHitSlop
                            hoverEnabled: true

                            onClicked: {
                                SettingsService.adapter.dock.marginBottom = 10;
                                marginInput.text = Qt.binding(marginTile.currentText);
                                SettingsService.save();
                            }
                        }
                    }
                }
            }
        }
        Item {
            height: SettingsConfig.tabBottomSpacerHeight
        }
    }
}
