pragma ComponentBehavior: Bound

import QtQuick

import qs.config

Rectangle {
    id: root

    property int animFastMs: 80
    property int animNormalMs: 200
    property real dotContainerMargin: 0
    property real dotSize: 8
    property real dotSlideOffset: -8
    property string failText: ""
    property bool failed: false
    readonly property alias fieldActiveFocus: field.activeFocus
    property real fontSize: 12
    property bool keepFocus: false
    property string placeholder: ""
    property bool selectByMouse: false
    readonly property alias text: field.text

    signal accepted

    function clear() {
        field.clear();
        dotModel.clear();
    }
    function forceActiveFocus() {
        field.forceActiveFocus();
    }

    TextInput {
        id: field

        anchors.fill: parent
        color: "transparent"
        echoMode: TextInput.NoEcho
        focus: true
        selectByMouse: root.selectByMouse

        cursorDelegate: Item {}

        onAccepted: root.accepted()
        onFocusChanged: {
            if (root.keepFocus && !field.activeFocus)
                forceActiveFocus();
        }
        onTextChanged: {
            if (text.length === 0) {
                dotModel.clear();
                return;
            }
            while (dotModel.count < text.length) {
                dotModel.append({});
            }
            while (dotModel.count > text.length) {
                dotModel.remove(dotModel.count - 1);
            }
        }

        // Dots
        Item {
            anchors.fill: parent
            anchors.margins: root.dotContainerMargin
            clip: true

            Row {
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2

                Behavior on x {
                    NumberAnimation {
                        duration: root.animNormalMs
                        easing.type: Easing.OutCubic
                    }
                }

                Repeater {
                    model: dotModel

                    delegate: Item {
                        height: root.dotSize
                        transformOrigin: Item.Center
                        width: root.dotSize

                        NumberAnimation on opacity {
                            duration: root.animFastMs
                            easing.type: Easing.Linear
                            from: 0.0
                            to: 1.0
                        }
                        NumberAnimation on scale {
                            duration: root.animNormalMs
                            easing.overshoot: 1.5
                            easing.type: Easing.OutBack
                            from: 0.0
                            to: 1.0
                        }

                        Item {
                            anchors.fill: parent
                            x: root.dotSlideOffset

                            NumberAnimation on x {
                                duration: root.animFastMs
                                easing.type: Easing.Linear
                                to: 0
                            }

                            Image {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectFit
                                source: GlobalConfig.inputEcho
                            }
                        }
                    }
                }
            }
        }

        // Placeholder
        Text {
            anchors.centerIn: parent
            color: ColorConfig.textDim
            font.family: FontConfig.fontFamily
            font.pixelSize: root.fontSize
            text: root.placeholder
            visible: field.text.length === 0 && root.placeholder !== ""
        }

        // Fail overlay
        Text {
            anchors.centerIn: parent
            color: ColorConfig.text
            font.family: FontConfig.fontFamily
            font.pixelSize: root.fontSize
            opacity: root.failed ? 1 : 0
            text: root.failText
            visible: root.failText !== ""
        }
    }
    ListModel {
        id: dotModel
    }
}
