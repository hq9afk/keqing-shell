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
    property int horizontalAlignment: Text.AlignHCenter
    property real horizontalPadding: 0
    property bool keepFocus: false
    property bool password: true
    property string placeholder: ""
    property bool selectByMouse: false
    property bool showCursor: false
    property alias text: field.text

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
        anchors.leftMargin: root.horizontalPadding
        anchors.rightMargin: root.horizontalPadding
        color: "transparent"
        echoMode: root.password ? TextInput.NoEcho : TextInput.Normal
        focus: true
        font.family: FontConfig.fontFamily
        font.pixelSize: root.fontSize
        selectByMouse: root.selectByMouse
        verticalAlignment: TextInput.AlignVCenter

        cursorDelegate: root.showCursor ? cursorComponent : hiddenCursorComponent

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
                x: {
                    switch (root.horizontalAlignment) {
                    case Text.AlignLeft:
                        return 0;
                    case Text.AlignRight:
                        return parent.width - width;
                    default:
                        return (parent.width - width) / 2;
                    }
                }
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
                        id: dot

                        required property int index

                        height: root.dotSize
                        transformOrigin: Item.Center
                        width: root.password ? root.dotSize : Math.max(root.dotSize, letterText.implicitWidth)

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
                                visible: root.password
                            }
                            Text {
                                id: letterText

                                anchors.centerIn: parent
                                color: ColorConfig.text
                                font.family: FontConfig.fontFamily
                                font.pixelSize: root.fontSize
                                text: field.text[dot.index] ?? ""
                                visible: !root.password
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
    Component {
        id: hiddenCursorComponent

        Item {}
    }
    Component {
        id: cursorComponent

        Rectangle {
            color: ColorConfig.text
            visible: field.cursorVisible
            width: 1
        }
    }
}
