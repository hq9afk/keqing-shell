pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import qs.elements
import qs.config

PanelWindow {
    id: root

    property alias browseRef: browse
    property bool fileMenuOpen: false
    required property var launcherRef
    property string mode: launcherRef.mode || LauncherConfig.modeDrun
    property var resultsModel: launcherRef.resultsModel
    property var selectedFileData: null

    signal dismissRequested
    signal entryActivated(var modelData)
    signal queryEdited(string text)

    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: launcherRef.isOpen

    onDismissRequested: launcherRef.goBack()
    onEntryActivated: modelData => launcherRef.launch(modelData)
    onQueryEdited: text => launcherRef.query = text
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
        Item {
            id: keyboard

            property bool active: root.visible && !root.fileMenuOpen
            property var launcherRef: root.launcherRef

            signal requestClose
            signal requestLaunch(bool shift)
            signal requestMove(int delta, bool shift)

            Keys.enabled: active
            Keys.priority: Keys.BeforeItem
            anchors.fill: parent
            visible: active

            Keys.onPressed: event => {
                if (!event)
                    return;

                const shift = !!(event.modifiers & Qt.ShiftModifier);
                let handled = true;

                switch (event.key) {
                case Qt.Key_Up:
                    keyboard.requestMove(-1, shift);
                    break;
                case Qt.Key_Down:
                    keyboard.requestMove(1, shift);
                    break;
                case Qt.Key_Enter:
                case Qt.Key_Return:
                    keyboard.requestLaunch(shift);
                    break;
                case Qt.Key_Escape:
                    keyboard.requestClose();
                    break;
                default:
                    handled = false;
                }

                if (handled)
                    event.accepted = true;
            }
            onRequestClose: () => {
                root.dismissRequested();
            }
            onRequestLaunch: _shift => {
                if (keyboard.launcherRef && keyboard.launcherRef.launch)
                    keyboard.launcherRef.launch();
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

                BrowsePanel {
                    id: browse

                    mode: root.mode
                    resultsModel: root.resultsModel

                    onEntryActivated: modelData => root.entryActivated(modelData)
                    onQueryEdited: text => root.queryEdited(text)
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
