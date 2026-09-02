pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.elements
import qs.service
import qs.modules.settings
import qs.config

Flickable {
    id: root

    readonly property bool idleGlobalEnabled: SettingsService.adapter.idle.enabled !== false
    readonly property bool overrideEnabled: {
        if (root.selectedScreen === "default")
            return true;
        var entry = SettingsService.idleDisplays[root.selectedScreen];
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

    clip: true
    contentHeight: col.implicitHeight

    Column {
        id: col

        spacing: SettingsConfig.tabColumnSpacing
        width: root.width

        SettingsGroup {
            contentSpacing: SettingsConfig.groupContentSpacingSm
            flat: true
            width: col.width

            Rectangle {
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
                        text: "Enable Idle Management"
                    }
                    Toggle {
                        active: root.idleGlobalEnabled

                        onToggled: SettingsService.setIdleEnabled(!active)
                    }
                }
            }
        }
        Row {
            id: screenRow

            spacing: SettingsConfig.screenSelectorSpacing
            visible: root.idleGlobalEnabled
            width: parent.width

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
            visible: root.idleGlobalEnabled && root.selectedScreen !== "default"
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

                onToggled: SettingsService.setIdleOverrideEnabled(root.selectedScreen, !root.overrideEnabled)
            }
        }
        SettingsGroup {
            contentSpacing: SettingsConfig.groupContentSpacingSm
            flat: true
            title: "Idle"
            visible: root.idleGlobalEnabled && root.overrideEnabled
            width: col.width

            Repeater {
                model: [
                    {
                        label: "Ambient Mode",
                        enableKey: "ambientEnabled",
                        timeKey: "ambientTimeoutSeconds",
                        min: 10,
                        max: 1800,
                        step: 1,
                        defaultVal: 150
                    },
                    {
                        label: "Screensaver",
                        enableKey: "screensaverEnabled",
                        timeKey: "screensaverTimeoutSeconds",
                        min: 10,
                        max: 1800,
                        step: 1,
                        defaultVal: 300
                    }
                ]

                delegate: Rectangle {
                    id: tile

                    required property int index
                    required property var modelData

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
                            text: tile.modelData.label
                        }
                        Rectangle {
                            border.color: numInput.activeFocus ? ColorConfig.accent : ColorConfig.textAlpha15
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
                                id: numInput

                                function currentText() {
                                    return Math.round(SettingsService.idleValue(root.selectedScreen, tile.modelData.timeKey)).toString();
                                }

                                anchors.fill: parent
                                anchors.margins: SettingsConfig.textFieldInset
                                color: ColorConfig.text
                                font.family: FontConfig.fontFamily
                                font.pixelSize: FontConfig.fontSettingsBody
                                horizontalAlignment: TextInput.AlignHCenter
                                selectByMouse: true
                                text: numInput.currentText()

                                onEditingFinished: {
                                    var v = parseFloat(text);
                                    if (!isNaN(v)) {
                                        v = Math.round(Math.max(tile.modelData.min, Math.min(tile.modelData.max, v)));
                                        SettingsService.setIdleValue(root.selectedScreen, tile.modelData.timeKey, v);
                                    }
                                    numInput.text = Qt.binding(numInput.currentText);
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
                                    var dv = tile.modelData.defaultVal;
                                    SettingsService.setIdleValue(root.selectedScreen, tile.modelData.timeKey, dv);
                                    numInput.text = Qt.binding(numInput.currentText);
                                }
                            }
                        }
                        Rectangle {
                            Layout.leftMargin: SettingsConfig.idleDividerLeftMargin
                            color: ColorConfig.textAlpha12
                            implicitHeight: SettingsConfig.idleDividerHeight
                            implicitWidth: SettingsConfig.dividerThickness
                        }
                        Toggle {
                            active: SettingsService.idleValue(root.selectedScreen, tile.modelData.enableKey)

                            onToggled: SettingsService.setIdleValue(root.selectedScreen, tile.modelData.enableKey, !active)
                        }
                    }
                }
            }
        }
    }
}
