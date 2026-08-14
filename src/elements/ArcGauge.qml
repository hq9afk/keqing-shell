pragma ComponentBehavior: Bound

import QtQuick

import qs.config

Item {
    id: root

    property color arcColor: ColorConfig.accent
    property string icon: ""
    property string label: ""
    property real value: 0

    height: 68
    width: 68

    onArcColorChanged: canvas.requestPaint()
    onValueChanged: canvas.requestPaint()

    Canvas {
        id: canvas

        anchors.fill: parent

        Component.onCompleted: requestPaint()
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            var cx = width / 2, cy = height / 2;
            var r = width / 2 - 6;

            // Dimmed background ring
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.strokeStyle = Qt.rgba(root.arcColor.r, root.arcColor.g, root.arcColor.b, 0.15);
            ctx.lineWidth = 6;
            ctx.stroke();

            // Foreground value arc (starts from top, clockwise)
            if (root.value > 0) {
                ctx.beginPath();
                ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + (root.value / 100) * 2 * Math.PI);
                ctx.strokeStyle = Qt.rgba(root.arcColor.r, root.arcColor.g, root.arcColor.b, 1);
                ctx.lineWidth = 6;
                ctx.lineCap = "round";
                ctx.stroke();
            }
        }
    }
    Column {
        anchors.centerIn: parent
        spacing: 1

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.arcColor
            font.family: IconConfig.fontFamily
            font.pixelSize: FontConfig.fontGaugeIcon
            text: root.icon
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: ColorConfig.text
            font.bold: true
            font.family: FontConfig.fontFamily
            font.pixelSize: FontConfig.fontGaugeValue
            text: Math.round(root.value) + "%"
        }
    }
}
