pragma ComponentBehavior: Bound

import QtQuick

import qs.settings
import qs.config

Item {
    id: root

    readonly property var filteredModel: {
        var q = inputField.text.trim().toLowerCase();
        if (!q)
            return root.model;
        return root.model.filter(function (item) {
            var label = typeof item === "string" ? item : (item[root.labelRole] ?? "");
            return label.toLowerCase().indexOf(q) !== -1;
        });
    }
    property string labelRole: "label"
    property var model: []
    property string placeholder: ""
    property string valueRole: "value"

    signal itemSelected(string value)

    function commit() {
        if (dropdown.highlightIndex >= 0 && dropdown.highlightIndex < root.filteredModel.length) {
            var item = root.filteredModel[dropdown.highlightIndex];
            var val = typeof item === "string" ? item : (item[root.valueRole] ?? "");
            root.itemSelected(val);
            inputField.text = "";
            inputField.focus = false;
        }
    }

    implicitHeight: SettingsConfig.comboBoxHeight
    implicitWidth: SettingsConfig.comboBoxWidth

    onFilteredModelChanged: {
        if (inputField.activeFocus) {
            if (filteredModel.length > 0) {
                dropdown.highlightIndex = 0;
                dropdown.open();
            } else {
                dropdown.close();
            }
        }
    }

    Rectangle {
        id: inputBox

        anchors.fill: parent
        border.color: inputField.activeFocus ? ColorConfig.accent : ColorConfig.textAlpha15
        border.width: SettingsConfig.hairlineBorderWidth
        color: ColorConfig.textAlpha07
        radius: SettingsConfig.fieldRadius

        Behavior on border.color {
            ColorAnimation {
                duration: GlobalConfig.animationFast
            }
        }

        Text {
            anchors.fill: parent
            anchors.leftMargin: SettingsConfig.comboBoxTextLeftMargin
            color: ColorConfig.textDim
            font.family: FontConfig.fontFamily
            font.pixelSize: FontConfig.fontSettingsBody
            text: root.placeholder
            verticalAlignment: Text.AlignVCenter
            visible: inputField.text === ""
        }
        TextInput {
            id: inputField

            anchors.fill: parent
            anchors.margins: 6
            color: ColorConfig.text
            font.family: FontConfig.fontFamily
            font.pixelSize: FontConfig.fontSettingsBody

            Keys.onDownPressed: event => {
                dropdown.highlightIndex = Math.min(dropdown.highlightIndex + 1, root.filteredModel.length - 1);
                event.accepted = true;
            }
            Keys.onEnterPressed: root.commit()
            Keys.onEscapePressed: event => {
                inputField.focus = false;
                event.accepted = true;
            }
            Keys.onReturnPressed: root.commit()
            Keys.onUpPressed: event => {
                dropdown.highlightIndex = Math.max(dropdown.highlightIndex - 1, 0);
                event.accepted = true;
            }
            onActiveFocusChanged: {
                if (activeFocus && root.filteredModel.length > 0) {
                    dropdown.highlightIndex = 0;
                    dropdown.open();
                } else {
                    dropdown.close();
                }
            }
        }
    }
    DropdownMenu {
        id: dropdown

        anchor: root
        captureKeyboard: false
        model: inputField.activeFocus ? root.filteredModel : []
        triggerVisible: false

        onItemSelected: value => {
            root.itemSelected(value);
            inputField.text = "";
            inputField.focus = false;
        }
    }
}
