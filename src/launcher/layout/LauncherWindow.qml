pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import qs.components
import qs.launcher
import qs.launcher.layout
import qs.config

PanelWindow {
    id: root

    property alias browseRef: browse
    property bool fileMenuOpen: false
    required property var launcherRef
    property string mode
    property var resultsModel: []
    property var selectedFileData: null

    signal dismissRequested
    signal entryActivated(var modelData)
    signal queryEdited(string text)

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    onVisibleChanged: {
        if (visible) {
            menuRect.opacity = LauncherConfig.menuEntranceOpacityStart;
            menuRect.scale = LauncherConfig.menuEntranceScaleStart;
            entranceAnim.restart();
        }
    }

    anchors {
        bottom: true
        left: true
        right: true
        top: true
    }
    PanelRect {
        id: menuRect

        function getHeight() {
            var entryH = LauncherConfig.entryHeight;
            var len = (browse && browse.resultsCount !== undefined) ? browse.resultsCount : 0;
            var maxE = LauncherConfig.maxVisibleEntries;
            var visible = Math.min(maxE, len);
            var borderPad = (border && border.width) ? border.width : 0;
            var outerAnchorsPad = borderPad;
            var innerMargins = LauncherConfig.innerMargins;
            var innerSpacing = LauncherConfig.innerSpacing;
            var listSpacing = LauncherConfig.listSpacing;
            var entriesSpacing = (visible > 1) ? listSpacing * (visible - 1) : 0;
            var entriesHeight = (visible > 0) ? (visible * entryH + entriesSpacing) : 0;
            var contentHeight = entryH + (visible > 0 ? (innerSpacing + entriesHeight) : 0);
            var totalPadding = (outerAnchorsPad * 2) + (innerMargins * 2);
            return contentHeight + totalPadding;
        }

        anchors.centerIn: parent
        border.width: LauncherConfig.menuBorderWidth
        clip: true
        color: Qt.rgba(ColorConfig.base.r, ColorConfig.base.g, ColorConfig.base.b, LauncherConfig.menuBgAlpha)
        height: getHeight()
        radius: LauncherConfig.menuRadius
        width: LauncherConfig.menuWidth
        z: 1

        Behavior on height {
            NumberAnimation {
                duration: LauncherConfig.menuAnimMs
                easing.type: Easing.InOutQuad
            }
        }

        ParallelAnimation {
            id: entranceAnim

            NumberAnimation {
                duration: LauncherConfig.menuEntranceMs
                easing.type: Easing.OutCubic
                property: "opacity"
                target: menuRect
                to: LauncherConfig.menuEntranceOpacityEnd
            }
            NumberAnimation {
                duration: LauncherConfig.menuEntranceMs
                easing.type: Easing.OutCubic
                property: "scale"
                target: menuRect
                to: LauncherConfig.menuEntranceScaleEnd
            }
        }
        KeyboardNavigation {
            id: keyboard

            active: root.visible && !root.fileMenuOpen
            anchors.fill: parent
            launcherRef: root.launcherRef

            onRequestClose: () => {
                root.dismissRequested();
            }
            onRequestLaunch: _shift => {
                if (root.launcherRef && root.launcherRef.launch)
                    root.launcherRef.launch();
            }
            onRequestMove: (delta, _shift) => {
                root.fileMenuOpen = false;
                if (browse && browse.list && browse.list.count > 0)
                    browse.list.currentIndex = (browse.list.currentIndex + browse.list.count + delta) % browse.list.count;
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: menuRect.border.width
                spacing: 0

                ColumnLayout {
                    id: browse

                    property int entryHeight: LauncherConfig.entryHeight
                    property int innerMargins: LauncherConfig.innerMargins
                    property int innerSpacing: LauncherConfig.innerSpacing
                    property alias input: search.input
                    property alias list: searchResults
                    property int maxVisibleEntries: LauncherConfig.maxVisibleEntries
                    property string mode: root.mode
                    readonly property int resultsCount: (browse.resultsModel && browse.resultsModel.length !== undefined) ? browse.resultsModel.length : 0
                    property var resultsModel: root.resultsModel

                    signal entryActivated(var modelData)
                    signal queryEdited(string text)

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.margins: innerMargins
                    Layout.preferredWidth: parent.width * LauncherConfig.menuBrowseWidthRatio
                    spacing: innerSpacing

                    onEntryActivated: root.entryActivated(modelData)
                    onQueryEdited: text => root.queryEdited(text)

                    SearchBar {
                        id: search

                        Layout.fillWidth: true
                        mode: browse.mode
                        size: browse.entryHeight

                        input.onTextChanged: {
                            browse.queryEdited(input.text);
                            searchResults.currentIndex = (browse.resultsCount > 0) ? 0 : -1;
                        }
                    }
                    Results {
                        id: searchResults

                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.preferredHeight: {
                            var visible = Math.min(browse.maxVisibleEntries, browse.resultsCount);
                            return visible * browse.entryHeight;
                        }
                        model: browse.resultsModel

                        Component.onCompleted: {
                            currentIndex = (browse.resultsCount > 0) ? 0 : -1;
                        }
                        onEntryActivated: browse.entryActivated(modelData)
                    }
                }
            }
        }
        MouseArea {
            id: menuArea

            acceptedButtons: Qt.NoButton
            anchors.fill: parent
        }
    }
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        z: -1

        onClicked: {
            if (!menuArea.containsMouse)
                root.dismissRequested();
        }
    }
}
