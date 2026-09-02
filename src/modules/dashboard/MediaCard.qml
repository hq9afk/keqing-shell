pragma ComponentBehavior: Bound

import QtQuick

import qs.elements
import qs.service
import qs.config

Item {
    id: root

    readonly property int _thumbSize: DashboardConfig.mediaThumbSize

    clip: true
    height: mediaCardRect.height
    visible: height > 0
    width: parent.width

    Behavior on height {
        NumberAnimation {
            duration: GlobalConfig.animationNormal
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: mediaCardRect

        border.color: ColorConfig.accent
        border.width: DashboardConfig.cardBorderWidth
        color: ColorConfig.overlay
        height: DashboardConfig.cardTopPadding + mediaHdr.height + DashboardConfig.cardHeaderContentGap + (ctrlRow.y + ctrlRow.height) + DashboardConfig.cardBottomPadding
        radius: DashboardConfig.cardRadius
        width: parent.width

        Item {
            id: mediaHdr

            height: DashboardConfig.cardHeaderHeight
            y: DashboardConfig.cardTopPadding

            anchors {
                left: parent.left
                leftMargin: DashboardConfig.cardHorizontalPadding
                right: parent.right
                rightMargin: DashboardConfig.cardHorizontalPadding
            }
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: ColorConfig.text
                font.bold: true
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontBody
                text: "Media"
            }
        }
        Item {
            id: mediaContentArea

            height: ctrlRow.y + ctrlRow.height

            anchors {
                left: parent.left
                leftMargin: DashboardConfig.cardHorizontalPadding
                right: parent.right
                rightMargin: DashboardConfig.cardHorizontalPadding
                top: mediaHdr.bottom
                topMargin: DashboardConfig.cardHeaderContentGap
            }
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
                    radius: DashboardConfig.mediaThumbRadius
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

                    spacing: DashboardConfig.mediaTitleSpacing

                    anchors {
                        left: thumb.right
                        leftMargin: DashboardConfig.mediaTitleLeftMargin
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

                height: DashboardConfig.mediaProgressRowHeight

                anchors {
                    left: parent.left
                    right: parent.right
                    top: topRow.bottom
                    topMargin: DashboardConfig.mediaProgressTopMargin
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

                height: DashboardConfig.mediaCtrlRowHeight

                anchors {
                    left: parent.left
                    right: parent.right
                    top: progressRow.bottom
                    topMargin: DashboardConfig.mediaCtrlTopMargin
                }
                Row {
                    anchors.centerIn: parent
                    spacing: DashboardConfig.mediaCtrlSpacing

                    Rectangle {
                        color: prevMa.containsMouse ? ColorConfig.overlay : "transparent"
                        height: DashboardConfig.mediaSideBtnSize
                        radius: DashboardConfig.mediaSideBtnRadius
                        width: DashboardConfig.mediaSideBtnSize

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
                        height: DashboardConfig.mediaPlayBtnSize
                        radius: DashboardConfig.mediaPlayBtnRadius
                        width: DashboardConfig.mediaPlayBtnSize

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
                        height: DashboardConfig.mediaSideBtnSize
                        radius: DashboardConfig.mediaSideBtnRadius
                        width: DashboardConfig.mediaSideBtnSize

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
    }
}
