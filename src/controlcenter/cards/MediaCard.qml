pragma ComponentBehavior: Bound

import QtQuick

import qs.components
import qs.service
import qs.controlcenter
import qs.controlcenter.layout
import qs.config

ControlCenterCard {
    id: root

    readonly property int _thumbSize: ControlCenterConfig.mediaThumbSize

    cardKey: "media"
    contentHeight: ctrlRow.y + ctrlRow.height
    title: "Media"

    Item {
        id: topRow

        height: root._thumbSize

        anchors {
            left: parent.left
            right: parent.right
        }
        Rectangle {
            id: thumb

            clip: true
            color: ColorConfig.overlay
            height: root._thumbSize
            radius: ControlCenterConfig.mediaThumbRadius
            width: root._thumbSize

            anchors {
                left: parent.left
                verticalCenter: parent.verticalCenter
            }
            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: MediaService.trackArtUrl
                visible: MediaService.trackArtUrl !== ""
            }
            Text {
                anchors.centerIn: parent
                color: ColorConfig.textDim
                font.family: IconConfig.fontFamily
                font.pixelSize: FontConfig.fontCardIcon
                text: IconConfig.musicNote
                visible: MediaService.trackArtUrl === ""
            }
        }
        Column {
            id: titleCol

            spacing: ControlCenterConfig.mediaTitleSpacing

            anchors {
                left: thumb.right
                leftMargin: ControlCenterConfig.mediaTitleLeftMargin
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            MarqueeText {
                color: ColorConfig.text
                fontFamily: FontConfig.fontFamily
                fontSize: FontConfig.fontBody
                text: MediaService.currentPlayer ? (MediaService.trackTitle !== "" ? MediaService.trackTitle : "Unknown") : "Nothing playing"
                width: parent.width
            }
            MarqueeText {
                color: ColorConfig.textDim
                fontFamily: FontConfig.fontFamily
                fontSize: FontConfig.fontBody - 1
                text: MediaService.currentPlayer ? (MediaService.trackArtist !== "" ? MediaService.trackArtist : "Unknown Artist") : ""
                width: parent.width
            }
        }
    }
    Item {
        id: progressRow

        height: ControlCenterConfig.mediaProgressRowHeight

        anchors {
            left: parent.left
            right: parent.right
            top: topRow.bottom
            topMargin: ControlCenterConfig.mediaProgressTopMargin
        }
        Text {
            color: ColorConfig.textDim
            font.family: FontConfig.fontFamily
            font.pixelSize: FontConfig.fontBody - 1
            text: MediaService.positionString + " / " + MediaService.lengthString

            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }
        }
    }
    Item {
        id: ctrlRow

        height: ControlCenterConfig.mediaCtrlRowHeight

        anchors {
            left: parent.left
            right: parent.right
            top: progressRow.bottom
            topMargin: ControlCenterConfig.mediaCtrlTopMargin
        }
        Row {
            anchors.centerIn: parent
            spacing: ControlCenterConfig.mediaCtrlSpacing

            Rectangle {
                color: prevMa.containsMouse ? ColorConfig.overlay : "transparent"
                height: ControlCenterConfig.mediaSideBtnSize
                radius: ControlCenterConfig.mediaSideBtnRadius
                width: ControlCenterConfig.mediaSideBtnSize

                Text {
                    anchors.centerIn: parent
                    color: MediaService.canGoPrevious ? ColorConfig.text : ColorConfig.textDim
                    font.family: IconConfig.fontFamily
                    font.pixelSize: FontConfig.fontMediaControl
                    text: IconConfig.playerPrev
                }
                MouseArea {
                    id: prevMa

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: MediaService.canGoPrevious
                    hoverEnabled: true

                    onClicked: MediaService.previous()
                }
            }
            Rectangle {
                color: playMa.containsMouse ? ColorConfig.overlay : ColorConfig.overlay
                height: ControlCenterConfig.mediaPlayBtnSize
                radius: ControlCenterConfig.mediaPlayBtnRadius
                width: ControlCenterConfig.mediaPlayBtnSize

                Text {
                    anchors.centerIn: parent
                    color: ColorConfig.text
                    font.family: IconConfig.fontFamily
                    font.pixelSize: FontConfig.fontMediaControl
                    text: MediaService.isPlaying ? IconConfig.playerPause : IconConfig.playerPlay
                }
                MouseArea {
                    id: playMa

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: MediaService.playPause()
                }
            }
            Rectangle {
                color: nextMa.containsMouse ? ColorConfig.overlay : "transparent"
                height: ControlCenterConfig.mediaSideBtnSize
                radius: ControlCenterConfig.mediaSideBtnRadius
                width: ControlCenterConfig.mediaSideBtnSize

                Text {
                    anchors.centerIn: parent
                    color: MediaService.canGoNext ? ColorConfig.text : ColorConfig.textDim
                    font.family: IconConfig.fontFamily
                    font.pixelSize: FontConfig.fontMediaControl
                    text: IconConfig.playerNext
                }
                MouseArea {
                    id: nextMa

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: MediaService.canGoNext
                    hoverEnabled: true

                    onClicked: MediaService.next()
                }
            }
        }
    }
}
