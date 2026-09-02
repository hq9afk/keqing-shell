pragma ComponentBehavior: Bound

import QtQuick

import qs.elements
import qs.service
import qs.modules.bar.components
import qs.config

WidgetPanel {
    id: subRoot

    property var device: null
    property string mode: ""

    clip: true
    implicitHeight: inner.implicitHeight + 2 * BarConfig.panelPadding
    implicitWidth: BarConfig.panelWidthMedium

    MouseArea {
        anchors.fill: parent
    }
    Text {
        anchors.left: parent.left
        anchors.leftMargin: BarConfig.panelPadding
        anchors.top: parent.top
        anchors.topMargin: BarConfig.panelSubPanelTopMargin
        color: ColorConfig.textDim
        elide: Text.ElideRight
        font.family: FontConfig.fontFamily
        font.pixelSize: FontConfig.fontBody - 1
        height: BarConfig.panelSubPanelRowHeight
        text: BluetoothService.deviceName(subRoot.device)
        verticalAlignment: Text.AlignVCenter
        width: parent.width - BarConfig.panelPadding - closeBtn.width - BarConfig.panelSubPanelTopMargin - BarConfig.panelSubPanelTopMargin
        z: 1
    }
    Rectangle {
        id: closeBtn

        anchors.right: parent.right
        anchors.rightMargin: BarConfig.panelSubPanelTopMargin
        anchors.top: parent.top
        anchors.topMargin: BarConfig.panelSubPanelTopMargin
        color: closeBtnMa.containsMouse ? ColorConfig.overlay : ColorConfig.overlay
        height: BarConfig.panelConfirmButtonSize
        radius: BarConfig.panelConfirmButtonRadius
        width: BarConfig.panelConfirmButtonSize
        z: 1

        Text {
            anchors.centerIn: parent
            color: ColorConfig.text
            font.family: IconConfig.fontFamily
            font.pixelSize: FontConfig.fontSubPanelClose
            text: IconConfig.close
        }
        MouseArea {
            id: closeBtnMa

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: PanelService.closeSubPanel()
        }
    }
    Column {
        id: inner

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: BarConfig.panelPadding
        spacing: BarConfig.panelRowGap
        width: parent.width - 2 * BarConfig.panelPadding

        // Disconnect
        Column {
            spacing: BarConfig.panelRowGap
            visible: subRoot.mode === "disconnect"
            width: parent.width

            Item {
                height: BarConfig.panelDialogSpacerHeight
                width: parent.width
            }
            Text {
                color: ColorConfig.text
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontBody - 1
                horizontalAlignment: Text.AlignHCenter
                text: "Disconnect?"
                width: parent.width
            }
            Item {
                height: BarConfig.panelSubPanelRowHeight
                width: parent.width

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: BarConfig.panelRowGap

                    Rectangle {
                        color: dOkMa.containsMouse ? Qt.rgba(1, 0.27, 0.27, 0.45) : Qt.rgba(1, 0.27, 0.27, 0.25)
                        height: BarConfig.panelConfirmButtonSize
                        radius: BarConfig.panelConfirmButtonRadius
                        width: dOkLabel.implicitWidth + BarConfig.panelDialogButtonPaddingH

                        Text {
                            id: dOkLabel

                            anchors.centerIn: parent
                            color: "#F44747"
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontBody - 1
                            text: "Disconnect"
                        }
                        MouseArea {
                            id: dOkMa

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onClicked: {
                                BluetoothService.disconnectDevice(subRoot.device);
                                PanelService.closeSubPanel();
                            }
                        }
                    }
                    Rectangle {
                        color: dCancelMa.containsMouse ? ColorConfig.overlay : ColorConfig.overlay
                        height: BarConfig.panelConfirmButtonSize
                        radius: BarConfig.panelConfirmButtonRadius
                        width: dCancelLabel.implicitWidth + BarConfig.panelDialogButtonPaddingH

                        Text {
                            id: dCancelLabel

                            anchors.centerIn: parent
                            color: ColorConfig.text
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontBody - 1
                            text: "Cancel"
                        }
                        MouseArea {
                            id: dCancelMa

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onClicked: PanelService.closeSubPanel()
                        }
                    }
                }
            }
        }

        // Forget
        Column {
            spacing: BarConfig.panelRowGap
            visible: subRoot.mode === "forget"
            width: parent.width

            Item {
                height: BarConfig.panelDialogSpacerHeight
                width: parent.width
            }
            Text {
                color: ColorConfig.text
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontBody - 1
                horizontalAlignment: Text.AlignHCenter
                text: "Forget?"
                width: parent.width
            }
            Item {
                height: BarConfig.panelSubPanelRowHeight
                width: parent.width

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: BarConfig.panelRowGap

                    Rectangle {
                        color: fOkMa.containsMouse ? Qt.rgba(1, 0.27, 0.27, 0.45) : Qt.rgba(1, 0.27, 0.27, 0.25)
                        height: BarConfig.panelConfirmButtonSize
                        radius: BarConfig.panelConfirmButtonRadius
                        width: fOkLabel.implicitWidth + BarConfig.panelDialogButtonPaddingH

                        Text {
                            id: fOkLabel

                            anchors.centerIn: parent
                            color: "#F44747"
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontBody - 1
                            text: "Forget"
                        }
                        MouseArea {
                            id: fOkMa

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onClicked: {
                                BluetoothService.forgetDevice(subRoot.device);
                                PanelService.closeSubPanel();
                            }
                        }
                    }
                    Rectangle {
                        color: fCancelMa.containsMouse ? ColorConfig.overlay : ColorConfig.overlay
                        height: BarConfig.panelConfirmButtonSize
                        radius: BarConfig.panelConfirmButtonRadius
                        width: fCancelLabel.implicitWidth + BarConfig.panelDialogButtonPaddingH

                        Text {
                            id: fCancelLabel

                            anchors.centerIn: parent
                            color: ColorConfig.text
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontBody - 1
                            text: "Cancel"
                        }
                        MouseArea {
                            id: fCancelMa

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onClicked: PanelService.closeSubPanel()
                        }
                    }
                }
            }
        }
    }
}
