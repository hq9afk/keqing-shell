pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.components
import qs.service
import qs.modules.settings
import qs.modules.settings.layout.components
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

        SettingsGroup {
            contentSpacing: SettingsConfig.groupContentSpacingSm
            flat: true
            title: "Geometry"
            width: col.width

            Repeater {
                model: [
                    {
                        label: "Bar Height",
                        min: 25,
                        max: 60,
                        step: 1,
                        defaultVal: 35,
                        getter: function () {
                            return SettingsService.adapter.bar.height;
                        },
                        setter: function (v) {
                            SettingsService.adapter.bar.height = v;
                        }
                    },
                    {
                        label: "Top Margin",
                        min: 0,
                        max: 60,
                        step: 1,
                        defaultVal: 10,
                        getter: function () {
                            return SettingsService.adapter.bar.marginTop;
                        },
                        setter: function (v) {
                            SettingsService.adapter.bar.marginTop = v;
                        }
                    },
                    {
                        label: "Horizontal Margin",
                        min: 0,
                        max: 80,
                        step: 1,
                        defaultVal: 20,
                        getter: function () {
                            return SettingsService.adapter.bar.marginH;
                        },
                        setter: function (v) {
                            SettingsService.adapter.bar.marginH = v;
                        }
                    },
                    {
                        label: "Screen Margin",
                        min: 0,
                        max: 80,
                        step: 1,
                        defaultVal: 20,
                        getter: function () {
                            return SettingsService.adapter.bar.screenMargin;
                        },
                        setter: function (v) {
                            SettingsService.adapter.bar.screenMargin = v;
                        }
                    },
                    {
                        label: "Background Opacity",
                        min: 0.0,
                        max: 1.0,
                        step: 0.05,
                        defaultVal: 0.0,
                        getter: function () {
                            return SettingsService.adapter.bar.backgroundOpacity;
                        },
                        setter: function (v) {
                            SettingsService.adapter.bar.backgroundOpacity = v;
                        }
                    }
                ]

                delegate: Rectangle {
                    id: numTile

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
                            text: numTile.modelData.label
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
                                    var v = numTile.modelData.getter();
                                    return numTile.modelData.step < 1 ? v.toFixed(2) : Math.round(v).toString();
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
                                        v = Math.max(numTile.modelData.min, Math.min(numTile.modelData.max, v));
                                        if (numTile.modelData.step >= 1)
                                            v = Math.round(v);
                                        numTile.modelData.setter(v);
                                        SettingsService.save();
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
                                    var dv = numTile.modelData.defaultVal;
                                    numTile.modelData.setter(dv);
                                    numInput.text = Qt.binding(numInput.currentText);
                                    SettingsService.save();
                                }
                            }
                        }
                    }
                }
            }
        }
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            border.color: ColorConfig.textAlpha12
            border.width: SettingsConfig.hairlineBorderWidth
            color: resetAllMa.containsMouse ? ColorConfig.accentAlpha15 : ColorConfig.textAlpha05
            height: SettingsConfig.resetPillHeight
            radius: GlobalConfig.radiusSm
            width: resetAllText.implicitWidth + SettingsConfig.resetPillPaddingH

            Behavior on color {
                ColorAnimation {
                    duration: GlobalConfig.animationFast
                }
            }

            Text {
                id: resetAllText

                anchors.centerIn: parent
                color: resetAllMa.containsMouse ? ColorConfig.accent : ColorConfig.text
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontSettingsBody
                opacity: resetAllMa.containsMouse ? 1.0 : SettingsConfig.mutedTextOpacity
                text: "↺  Reset all to defaults"

                Behavior on color {
                    ColorAnimation {
                        duration: GlobalConfig.animationFast
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: GlobalConfig.animationFast
                    }
                }
            }
            MouseArea {
                id: resetAllMa

                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    SettingsService.adapter.bar.height = 35;
                    SettingsService.adapter.bar.marginTop = 10;
                    SettingsService.adapter.bar.marginH = 20;
                    SettingsService.adapter.bar.screenMargin = 20;
                    SettingsService.adapter.bar.backgroundOpacity = 0;
                    SettingsService.save();
                }
            }
        }
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
