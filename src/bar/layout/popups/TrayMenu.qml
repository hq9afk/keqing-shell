pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.bar
import qs.config

PopupWindow {
    id: root

    property bool _open: false
    property var anchorItem: null
    property real anchorX: 0
    property real anchorY: 0
    property bool isSubMenu: false
    property var menu: isSubMenu ? null : (trayItem ? trayItem.menu : null)
    readonly property real menuWidth: BarConfig.trayMenuWidth
    property var screen: null
    property var trayItem: null

    function hideMenu() {
        _open = false;
        for (var i = 0; i < col.children.length; i++) {
            var c = col.children[i];
            if (c && c.subMenu) {
                c.subMenu.hideMenu();
                c.subMenu.destroy();
                c.subMenu = null;
            }
        }
    }
    function showAt(item, x, y) {
        if (!item)
            return;
        anchorItem = item;
        anchorX = x;
        anchorY = y;
        _open = false;
        visible = true;
        Qt.callLater(function () {
            root.anchor.updateAnchor();
            root._open = true;
        });
    }

    anchor.item: anchorItem
    anchor.rect.x: {
        if (!anchorItem)
            return anchorX;
        if (isSubMenu)
            return anchorX;
        if (!screen)
            return 0;
        var g = anchorItem.mapToItem(null, 0, 0);
        var globalX = BarConfig.barMarginH + g.x;
        var centerX = globalX + anchorItem.width / 2;
        var x = centerX - implicitWidth / 2;
        var m = BarConfig.screenMargin;
        x = Math.max(m, Math.min(x, screen.width - implicitWidth - m));
        return x - globalX;
    }
    anchor.rect.y: {
        if (!anchorItem)
            return anchorY;
        if (isSubMenu)
            return anchorY;
        var g = anchorItem.mapToItem(null, 0, 0);
        var globalY = BarConfig.barMarginTop + g.y;
        var barBottomY = BarConfig.barMarginTop + BarConfig.barHeight + BarConfig.panelGap;
        if (globalY >= barBottomY)
            return anchorItem.height;
        return barBottomY - globalY;
    }
    color: "transparent"
    implicitHeight: Math.min((screen ? screen.height * BarConfig.trayMenuMaxHeightRatio : 600), col.implicitHeight + BarConfig.trayMenuTopPad)
    implicitWidth: menuWidth
    visible: false

    onImplicitHeightChanged: {
        if (visible && anchorItem)
            Qt.callLater(function () {
                root.anchor.updateAnchor();
            });
    }

    QsMenuOpener {
        id: opener

        menu: root.menu
    }
    Item {
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: root.hideMenu()
    }
    Item {
        id: animClip

        clip: true
        height: root._open ? root.implicitHeight : 0
        width: root.implicitWidth

        Behavior on height {
            NumberAnimation {
                duration: GlobalConfig.animationNormal
                easing.type: Easing.OutCubic

                onRunningChanged: {
                    if (!running && !root._open && animClip.height === 0)
                        root.visible = false;
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            border.color: ColorConfig.accent
            border.width: BarConfig.trayMenuBorderWidth
            color: ColorConfig.overlay
            radius: GlobalConfig.radiusSm + BarConfig.trayMenuRadiusExtra
        }
        Column {
            id: col

            anchors.left: parent.left
            anchors.margins: BarConfig.trayMenuPadding
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 0

            Repeater {
                model: opener.children ? [...opener.children.values] : []

                delegate: Item {
                    id: entry

                    required property var modelData
                    property var subMenu: null

                    height: (modelData && modelData.isSeparator) ? BarConfig.trayMenuSeparatorHeight : BarConfig.trayMenuItemHeight
                    width: col.width

                    Component.onDestruction: {
                        if (subMenu) {
                            subMenu.destroy();
                            subMenu = null;
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        color: ColorConfig.accent
                        height: BarConfig.trayMenuSeparatorLineHeight
                        visible: entry.modelData && entry.modelData.isSeparator
                        width: parent.width - BarConfig.trayMenuSeparatorWidthOffset
                    }
                    Rectangle {
                        anchors.fill: parent
                        color: rowMa.containsMouse ? ColorConfig.textAlpha13 : "transparent"
                        radius: GlobalConfig.radiusSm
                        visible: !(entry.modelData && entry.modelData.isSeparator)

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: BarConfig.trayMenuRowPaddingH
                            anchors.rightMargin: BarConfig.trayMenuRowPaddingH
                            spacing: BarConfig.trayMenuRowPaddingH

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                color: ColorConfig.accent
                                font.family: IconConfig.fontFamily
                                font.pixelSize: FontConfig.fontBody
                                text: IconConfig.check
                                visible: entry.modelData && (entry.modelData.checkState === Qt.Checked || entry.modelData.checked === true)
                            }
                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                fillMode: Image.PreserveAspectFit
                                height: BarConfig.iconSize
                                smooth: true
                                source: entry.modelData ? (entry.modelData.icon ?? "") : ""
                                visible: entry.modelData && (entry.modelData.icon ?? "") !== ""
                                width: BarConfig.iconSize
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                color: (entry.modelData && entry.modelData.enabled === false) ? ColorConfig.textDim : ColorConfig.text
                                elide: Text.ElideRight
                                font.family: FontConfig.fontFamily
                                font.pixelSize: FontConfig.fontBody
                                text: entry.modelData ? (entry.modelData.text !== "" ? entry.modelData.text.replace(/[\n\r]+/g, ' ') : "…") : ""
                                width: parent.width - BarConfig.trayMenuLabelWidthOffset
                            }
                        }
                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: BarConfig.trayMenuRowPaddingH
                            anchors.verticalCenter: parent.verticalCenter
                            color: ColorConfig.text
                            font.family: IconConfig.fontFamily
                            font.pixelSize: FontConfig.fontBody
                            text: IconConfig.chevronRight
                            visible: entry.modelData && entry.modelData.hasChildren
                        }
                        MouseArea {
                            id: rowMa

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            enabled: entry.modelData && entry.modelData.enabled !== false && !(entry.modelData.isSeparator ?? false)
                            hoverEnabled: true

                            onClicked: {
                                if (!entry.modelData)
                                    return;
                                if (entry.modelData.hasChildren) {
                                    if (entry.subMenu) {
                                        entry.subMenu.hideMenu();
                                        entry.subMenu.destroy();
                                        entry.subMenu = null;
                                    } else {
                                        for (var i = 0; i < col.children.length; i++) {
                                            var sib = col.children[i];
                                            if (sib !== entry && sib.subMenu) {
                                                sib.subMenu.hideMenu();
                                                sib.subMenu.destroy();
                                                sib.subMenu = null;
                                            }
                                        }
                                        entry.subMenu = Qt.createComponent("TrayMenu.qml").createObject(root, {
                                            "menu": entry.modelData,
                                            "isSubMenu": true,
                                            "screen": root.screen
                                        });
                                        if (entry.subMenu) {
                                            entry.subMenu.anchorItem = entry;
                                            entry.subMenu.anchorX = BarConfig.trayMenuSubmenuOffsetX;
                                            entry.subMenu.anchorY = 0;
                                            entry.subMenu.visible = true;
                                            Qt.callLater(function () {
                                                entry.subMenu.anchor.updateAnchor();
                                            });
                                        }
                                    }
                                } else {
                                    entry.modelData.triggered();
                                    root.hideMenu();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
