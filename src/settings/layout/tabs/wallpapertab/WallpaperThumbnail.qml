pragma ComponentBehavior: Bound

import QtQuick

import qs.settings
import qs.wallpaper
import qs.config

Rectangle {
    id: thumb

    required property string path
    property string previewSource: ""
    required property bool selected

    signal clicked(string path)

    border.color: selected ? ColorConfig.accentAlt : "transparent"
    border.width: SettingsConfig.thumbnailBorderWidth
    clip: true
    color: ColorConfig.lavenderSubtle
    radius: GlobalConfig.radiusSm + SettingsConfig.thumbnailRadiusBoost

    Behavior on border.color {
        ColorAnimation {
            duration: SettingsConfig.quickColorAnimMs
        }
    }

    Image {
        anchors.fill: parent
        anchors.margins: SettingsConfig.thumbnailImageInset
        asynchronous: true
        cache: false
        clip: true
        fillMode: Image.PreserveAspectCrop
        opacity: status === Image.Ready ? 1.0 : 0.0
        smooth: true
        source: "file://" + (thumb.previewSource !== "" ? thumb.previewSource : thumb.path)
        sourceSize: Qt.size(width, height)

        Behavior on opacity {
            NumberAnimation {
                duration: SettingsConfig.toggleAnimMs
            }
        }
    }
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        color: ColorConfig.overlay
        height: fileLabel.implicitHeight + SettingsConfig.thumbnailLabelPadding

        Text {
            id: fileLabel

            anchors.left: parent.left
            anchors.leftMargin: SettingsConfig.thumbnailLabelMargin
            anchors.right: parent.right
            anchors.rightMargin: SettingsConfig.thumbnailLabelMargin
            anchors.verticalCenter: parent.verticalCenter
            color: "white"
            elide: Text.ElideRight
            font.family: FontConfig.fontFamily
            font.pixelSize: FontConfig.fontSettingsBody
            text: thumb.path.split('/').pop()
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onClicked: thumb.clicked(thumb.path)
    }
}
