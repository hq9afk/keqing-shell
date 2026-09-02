pragma ComponentBehavior: Bound

import QtQuick

import qs.service
import qs.config

Item {
    id: root

    property var _buttonItem: null
    property real _lockedCenterX: -1
    property var _openData: null
    property real _panelH: 0
    property real _panelW: 0
    property real _panelX: 0
    property real _panelY: 0
    property var attachTo: null
    property bool isClosing: false
    property bool isPanelOpen: false
    property bool isPanelVisible: false
    property Component panelContent: null
    property var screen: null

    signal closed
    signal opened
    signal panelPositionChanged

    function _finalizeClose() {
        closeWatchdog.stop();
        isPanelVisible = false;
        isPanelOpen = false;
        isClosing = false;
        _panelH = 0;
        _lockedCenterX = -1;
        if (attachTo)
            PanelService.closedSubPanel(root);
        else
            PanelService.closedPanel(root);
        closed();
    }
    function close() {
        if (!isPanelOpen || isClosing)
            return;
        isClosing = true;
        closeWatchdog.restart();
    }
    function onEscapePressed() {
        close();
    }
    function open(buttonItem, data) {
        _buttonItem = buttonItem || null;
        _openData = data || null;
        isClosing = false;
        isPanelOpen = true;
        if (attachTo)
            PanelService.openSubPanel(root);
        else
            PanelService.willOpenPanel(root);
    }
    function setPosition() {
        if (!root.width || !root.height || !contentLoader.item)
            return;
        var contentW = contentLoader.item.implicitWidth || contentLoader.item.width || BarConfig.dropPanelDefaultContentWidth;
        var contentH = contentLoader.item.implicitHeight || contentLoader.item.height || BarConfig.dropPanelDefaultContentHeight;
        var margin = BarConfig.barMarginH;

        var panelY, w, x;
        if (attachTo) {
            panelY = attachTo._panelY + attachTo._panelH + BarConfig.panelGap;
            w = attachTo._panelW;
            x = attachTo._panelX;
        } else {
            panelY = BarConfig.barMarginTop + BarConfig.barHeight + BarConfig.panelGap;
            w = Math.min(contentW, root.width - 2 * margin);
            var centerX;
            if (_lockedCenterX >= 0) {
                centerX = _lockedCenterX;
            } else {
                centerX = root.width / 2;
                if (_buttonItem && typeof _buttonItem.mapToItem === "function") {
                    var local = _buttonItem.mapToItem(null, 0, 0);
                    centerX = BarConfig.barMarginH + local.x + _buttonItem.width / 2;
                }
                _lockedCenterX = centerX;
            }
            x = centerX - w / 2;
            x = Math.max(margin, Math.min(x, root.width - w - margin));
        }

        var h = Math.min(contentH, root.height - panelY - margin);

        _panelW = w;
        _panelH = h;
        _panelX = x;
        _panelY = panelY;
        panelPositionChanged();
    }
    function toggle(buttonItem) {
        if (isPanelOpen && !isClosing)
            close();
        else
            open(buttonItem);
    }

    anchors.fill: parent

    Component.onCompleted: PanelService.registerPanel(root)
    Component.onDestruction: PanelService.unregisterPanel(root)
    onHeightChanged: if (isPanelOpen)
        setPosition()
    onWidthChanged: if (isPanelOpen)
        setPosition()

    Connections {
        function onIsClosingChanged() {
            if (root.attachTo && root.attachTo.isClosing && root.isPanelOpen && !root.isClosing)
                root.close();
        }
        function onPanelPositionChanged() {
            if (root.isPanelVisible)
                root.setPosition();
        }

        enabled: root.attachTo !== null && root.isPanelOpen
        target: root.attachTo
    }
    Connections {
        function onImplicitHeightChanged() {
            if (root.isPanelVisible)
                root.setPosition();
        }
        function onImplicitWidthChanged() {
            if (root.isPanelVisible)
                root.setPosition();
        }

        ignoreUnknownSignals: true
        target: contentLoader.item
    }
    Timer {
        id: closeWatchdog

        interval: GlobalConfig.animationNormal * 3

        onTriggered: if (root.isClosing)
            root._finalizeClose()
    }
    Item {
        id: container

        clip: true
        height: root.isPanelVisible && !root.isClosing ? root._panelH : 0
        visible: root.isPanelOpen
        width: root._panelW
        x: root._panelX
        y: root._panelY

        Behavior on height {
            NumberAnimation {
                duration: GlobalConfig.animationNormal
                easing.type: Easing.OutCubic

                onRunningChanged: {
                    if (!running && root.isClosing && container.height === 0)
                        Qt.callLater(root._finalizeClose);
                }
            }
        }

        Loader {
            id: contentLoader

            active: root.isPanelOpen
            anchors.fill: parent
            sourceComponent: root.panelContent

            onLoaded: {
                if (root._openData) {
                    var d = root._openData;
                    for (var k in d)
                        item[k] = d[k];
                }
                Qt.callLater(function () {
                    root.setPosition();
                    root.isPanelVisible = true;
                    root.opened();
                });
            }
        }
    }
}
