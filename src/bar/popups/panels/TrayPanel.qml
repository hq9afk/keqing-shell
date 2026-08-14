pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

import qs.elements
import qs.bar.components
import qs.bar.popups
import qs.service
import qs.config

WidgetPanel {
    id: root

    readonly property int cellSize: BarConfig.iconSize + BarConfig.trayCellIconPadding
    readonly property int columns: BarConfig.trayColumns
    property var screen: null

    implicitHeight: headerItem.height + BarConfig.trayHeaderContentGap + grid.implicitHeight + BarConfig.panelPadding * 2
    implicitWidth: columns * cellSize + BarConfig.panelPadding * 2

    TrayMenu {
        id: trayMenu

        screen: root.screen
    }
    MouseArea {
        anchors.fill: parent
    }
    Column {
        spacing: 0

        anchors {
            fill: parent
            margins: BarConfig.panelPadding
        }
        Item {
            id: headerItem

            height: BarConfig.panelHeaderHeight
            width: parent.width

            Text {
                anchors.verticalCenter: parent.verticalCenter
                color: ColorConfig.text
                font.bold: true
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontBody + 1
                text: "System Tray"
            }
            Rectangle {
                color: closeMa.containsMouse ? ColorConfig.overlay : ColorConfig.overlay
                height: BarConfig.panelCloseButtonSize
                radius: BarConfig.panelCloseButtonRadius
                width: BarConfig.panelCloseButtonSize

                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                Text {
                    anchors.centerIn: parent
                    color: ColorConfig.text
                    font.family: IconConfig.fontFamily
                    font.pixelSize: FontConfig.fontPanelActionIcon
                    text: IconConfig.close
                }
                MouseArea {
                    id: closeMa

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: PanelService.closePanel()
                }
            }
        }
        Divider {
            width: parent.width
        }
        Item {
            height: BarConfig.panelSectionGap
            width: parent.width
        }
        Grid {
            id: grid

            columns: root.columns
            spacing: BarConfig.trayGridSpacing
            width: parent.width

            Repeater {
                model: SystemTray.items

                delegate: Item {
                    id: trayBtn

                    required property SystemTrayItem modelData

                    height: root.cellSize
                    width: root.cellSize

                    Rectangle {
                        anchors.fill: parent
                        color: btnHover.containsMouse ? ColorConfig.overlay : "transparent"
                        radius: BarConfig.trayButtonRadius
                    }
                    IconImage {
                        anchors.centerIn: parent
                        height: BarConfig.iconSize
                        smooth: true
                        source: trayBtn.modelData.icon
                        width: BarConfig.iconSize
                    }
                    MouseArea {
                        id: btnHover

                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true

                        onClicked: function (mouse) {
                            if (mouse.button === Qt.RightButton && trayBtn.modelData.hasMenu)
                                PanelService.showTrayMenu(root.screen, trayBtn.modelData, trayMenu, trayBtn);
                            else
                                trayBtn.modelData.activate();
                        }
                    }
                }
            }
        }
    }
}
