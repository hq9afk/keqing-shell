pragma ComponentBehavior: Bound

import QtQuick

import qs.modules.settings
import qs.modules.wallpaper
import qs.config

Item {
    id: root

    property int minValue: 1
    property int value: 1

    signal valueChangeRequested(int n)

    function clamp(n) {
        return Math.max(root.minValue, n);
    }

    implicitHeight: WallpaperConfig.controlRowHeight - SettingsConfig.groupContentSpacingSm
    implicitWidth: decBtn.width + numBox.width + incBtn.width + WallpaperConfig.dropdownBtnSpacing * 2

    Row {
        anchors.fill: parent
        spacing: WallpaperConfig.dropdownBtnSpacing

        Rectangle {
            id: decBtn

            color: ColorConfig.lavenderAlpha20
            height: WallpaperConfig.controlRowHeight - SettingsConfig.groupContentSpacingSm
            opacity: root.value <= root.minValue ? SettingsConfig.faintOpacity : 1
            radius: GlobalConfig.radiusSm
            width: WallpaperConfig.controlRowHeight

            Text {
                anchors.centerIn: parent
                color: ColorConfig.text
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontSettingsBody
                text: "-"
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: root.value > root.minValue

                onClicked: root.valueChangeRequested(root.clamp(root.value - 1))
            }
        }
        Rectangle {
            id: numBox

            border.color: numInput.activeFocus ? ColorConfig.accent : ColorConfig.textAlpha15
            border.width: SettingsConfig.hairlineBorderWidth
            color: ColorConfig.textAlpha07
            height: WallpaperConfig.controlRowHeight - SettingsConfig.groupContentSpacingSm
            radius: SettingsConfig.fieldRadius
            width: SettingsConfig.numberFieldWidth

            Behavior on border.color {
                ColorAnimation {
                    duration: GlobalConfig.animationFast
                }
            }

            TextInput {
                id: numInput

                function currentText() {
                    return root.value.toString();
                }

                anchors.fill: parent
                anchors.margins: SettingsConfig.textFieldInset
                color: ColorConfig.text
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontSettingsBody
                horizontalAlignment: TextInput.AlignHCenter
                selectByMouse: true
                text: numInput.currentText()

                validator: IntValidator {
                    bottom: root.minValue
                }

                onEditingFinished: {
                    var v = parseInt(text, 10);
                    if (!isNaN(v))
                        root.valueChangeRequested(root.clamp(v));
                    numInput.text = Qt.binding(numInput.currentText);
                }
            }
        }
        Rectangle {
            id: incBtn

            color: ColorConfig.lavenderAlpha20
            height: WallpaperConfig.controlRowHeight - SettingsConfig.groupContentSpacingSm
            radius: GlobalConfig.radiusSm
            width: WallpaperConfig.controlRowHeight

            Text {
                anchors.centerIn: parent
                color: ColorConfig.text
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontSettingsBody
                text: "+"
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                onClicked: root.valueChangeRequested(root.clamp(root.value + 1))
            }
        }
    }
}
