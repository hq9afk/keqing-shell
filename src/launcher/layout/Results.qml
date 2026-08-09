pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.launcher
import qs.config

RowLayout {
    id: root

    property alias count: list.count
    property alias currentIndex: list.currentIndex
    property alias currentItem: list.currentItem
    property alias model: list.model
    property alias visibleEntries: list.visibleEntries

    signal entryActivated(var modelData)

    Layout.fillWidth: true
    spacing: LauncherConfig.resultsSpacing

    Column {
        id: bullets

        height: list.height
        spacing: LauncherConfig.bulletsSpacing

        Repeater {
            model: root.visibleEntries

            Item {
                required property int index
                property real size: (list && list.contentItem && list.contentItem.children && list.contentItem.children[index]) ? list.contentItem.children[index].height : (parent ? parent.height : 0)

                height: size
                width: size

                IconImage {
                    anchors.centerIn: parent
                    height: LauncherConfig.bulletsIconSize
                    smooth: true
                    source: GlobalConfig.constellation(index + 1)
                    width: LauncherConfig.bulletsIconSize
                }
            }
        }
    }
    ListView {
        id: list

        property int entryHeight: LauncherConfig.entryHeight
        property int visibleEntries: {
            if (count === 0 || contentHeight === 0)
                return 0;
            var avg = contentHeight / count;
            if (avg <= 0)
                return 0;
            var n = Math.ceil(height / avg);
            if (n < 1)
                n = 1;
            if (n > LauncherConfig.maxVisibleEntries)
                n = LauncherConfig.maxVisibleEntries;
            if (n > count)
                n = count;
            return n;
        }

        function snapToEntry() {
            if (count < 1)
                return;
            var step = entryHeight + spacing;
            if (step <= 0)
                return;
            var maxY = Math.max(0, contentHeight - height);
            var y = Math.max(0, Math.min(contentY, maxY));
            var targetY = Math.round(y / step) * step;
            targetY = Math.max(0, Math.min(targetY, maxY));
            if (Math.abs(targetY - contentY) < 0.5)
                return;
            snapAnim.to = targetY;
            snapAnim.start();
        }

        Layout.fillHeight: true
        Layout.fillWidth: true
        clip: true
        highlightMoveDuration: LauncherConfig.highlightMoveMs
        highlightRangeMode: ListView.ApplyRange
        highlightResizeDuration: LauncherConfig.highlightResizeMs
        keyNavigationWraps: true
        preferredHighlightBegin: 0
        preferredHighlightEnd: height
        spacing: LauncherConfig.listSpacing
        z: 0

        delegate: Item {
            id: entry

            required property int index
            property bool isCurrent: ListView.isCurrentItem
            required property var modelData

            height: (ListView.view && ListView.view.entryHeight) ? ListView.view.entryHeight : LauncherConfig.entryHeight
            width: parent ? parent.width : 0
            z: 1

            Rectangle {
                anchors.fill: parent
                border.color: hover.containsMouse && !entry.isCurrent ? ColorConfig.accent : "transparent"
                border.width: LauncherConfig.entryBorderWidth
                color: ColorConfig.textAlpha03
                radius: LauncherConfig.entryRadius
                z: 0
            }
            MouseArea {
                id: hover

                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    if (ListView.view)
                        ListView.view.currentIndex = index;
                    root.entryActivated(entry.modelData);
                }
            }
            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                anchors.fill: parent
                anchors.leftMargin: LauncherConfig.entryContentMargin
                anchors.rightMargin: LauncherConfig.entryContentMargin
                spacing: LauncherConfig.entryContentSpacing

                Item {
                    property bool useGlyph: !!(entry.modelData && entry.modelData.iconGlyph && String(entry.modelData.iconGlyph).length > 0)

                    Layout.alignment: Qt.AlignVCenter
                    height: LauncherConfig.entryIconSize
                    width: LauncherConfig.entryIconSize

                    IconImage {
                        anchors.fill: parent
                        source: Quickshell.iconPath(entry.modelData?.icon ?? "application-x-executable", "image-missing")
                        visible: !parent.useGlyph
                    }
                    Text {
                        anchors.centerIn: parent
                        color: ColorConfig.text
                        font.family: IconConfig.fontFamily
                        font.pointSize: LauncherConfig.entryIconGlyphPointSize
                        horizontalAlignment: Text.AlignHCenter
                        text: entry.modelData?.iconGlyph ?? ""
                        verticalAlignment: Text.AlignVCenter
                        visible: parent.useGlyph
                    }
                }
                Item {
                    id: textBox

                    property bool hasPath: !!(entry.modelData && entry.modelData.path && String(entry.modelData.path).length > 0)

                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    height: parent.height

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: textBox.hasPath ? undefined : parent.verticalCenter
                        color: ColorConfig.text
                        elide: Text.ElideRight
                        font.family: FontConfig.fontFamily
                        font.pointSize: LauncherConfig.entryTitlePointSize
                        horizontalAlignment: Text.AlignLeft
                        maximumLineCount: 1
                        text: entry.modelData.name
                        y: textBox.hasPath ? LauncherConfig.entryTitleOffsetY : 0
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        color: ColorConfig.text
                        elide: Text.ElideMiddle
                        font.family: FontConfig.fontFamily
                        font.pointSize: LauncherConfig.entrySubtitlePointSize
                        horizontalAlignment: Text.AlignLeft
                        maximumLineCount: 1
                        opacity: LauncherConfig.entrySubtitleOpacity
                        text: {
                            var p = entry.modelData.path || "";
                            var home = Quickshell.env("HOME") || "";
                            return home && (p === home || p.startsWith(home + "/")) ? "~" + p.slice(home.length) : p;
                        }
                        visible: textBox.hasPath
                        y: LauncherConfig.entrySubtitleOffsetY
                    }
                }
            }
        }
        highlight: Rectangle {
            id: passiveHighlight

            border.color: ColorConfig.accentAlt
            border.width: LauncherConfig.highlightBorderWidth
            color: "transparent"
            opacity: LauncherConfig.highlightOpacity
            radius: LauncherConfig.highlightRadius
            z: -1

            Behavior on height {
                NumberAnimation {
                    duration: list.highlightResizeDuration
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: list.highlightMoveDuration
                    easing.type: Easing.OutCubic
                }
            }
        }

        onDraggingChanged: if (!dragging)
            snapToEntry()
        onFlickEnded: snapToEntry()
        onMovementEnded: snapToEntry()
        onMovementStarted: snapAnim.stop()

        NumberAnimation {
            id: snapAnim

            duration: LauncherConfig.snapAnimMs
            easing.type: Easing.OutCubic
            property: "contentY"
            target: list
        }
    }
}
