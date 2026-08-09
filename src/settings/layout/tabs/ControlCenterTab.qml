pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.service
import qs.settings
import qs.settings.layout.components
import qs.config

Column {
    id: root

    readonly property var cardMeta: ({
            "battery": {
                label: "Battery",
                hint: "Charge level & time remaining"
            },
            "systemStats": {
                label: "System Stats",
                hint: "CPU, RAM, Disk & sliders"
            },
            "cpuTemp": {
                label: "CPU Temperature",
                hint: "CPU core temperatures"
            },
            "gpuTemp": {
                label: "GPU Temperature",
                hint: "GPU temperature (hidden if no GPU)"
            },
            "media": {
                label: "Media",
                hint: "Media playback controls"
            },
            "volume": {
                label: "Volume",
                hint: "Audio slider & mute"
            }
        })
    readonly property var defaultOrder: ["battery", "systemStats", "cpuTemp", "gpuTemp", "media", "volume"]
    readonly property var effectiveOrder: {
        var co = SettingsService.controlCenter.cardOrder;
        return (co && co.length > 0) ? Array.from(co) : root.defaultOrder;
    }

    function disableCard(id) {
        var cards = Array.from(SettingsService.adapter.controlCenter.cards);
        var idx = cards.indexOf(id);
        if (idx !== -1) {
            cards.splice(idx, 1);
            SettingsService.setControlCenter({
                cards: cards
            });
        }
    }
    function enableCard(id) {
        var order = root.effectiveOrder;
        var currentCards = Array.from(SettingsService.controlCenter.cards);
        var enabledSet = {};
        for (var i = 0; i < currentCards.length; i++)
            enabledSet[currentCards[i]] = true;
        enabledSet[id] = true;
        var newCards = order.filter(function (oid) {
            return enabledSet[oid];
        });
        SettingsService.setControlCenter({
            cards: newCards
        });
    }
    function moveCard(from, to) {
        if (from === to || to < 0 || to >= root.effectiveOrder.length)
            return;
        var order = root.effectiveOrder.slice();
        var item = order.splice(from, 1)[0];
        order.splice(to, 0, item);
        var currentCards = Array.from(SettingsService.controlCenter.cards);
        var enabledSet = {};
        for (var i = 0; i < currentCards.length; i++)
            enabledSet[currentCards[i]] = true;
        var newCards = order.filter(function (id) {
            return enabledSet[id];
        });
        SettingsService.setControlCenter({
            cardOrder: order,
            cards: newCards
        });
    }

    spacing: 0

    SettingsGroup {
        title: "Cards"
        width: root.width

        Item {
            id: orderHolder

            property int rowHeight: SettingsConfig.controlCenterRowHeight
            property int rowSpacing: SettingsConfig.reorderItemSpacing

            height: cardRepeater.count > 0 ? cardRepeater.count * (rowHeight + rowSpacing) - rowSpacing : rowHeight
            width: parent.width

            Repeater {
                id: cardRepeater

                model: root.effectiveOrder

                delegate: Item {
                    id: orderCard

                    property int dragStartIndex: -1
                    property int dragTargetIndex: -1
                    property bool dragging: false
                    property real grabGlobalY: 0
                    required property int index
                    required property var modelData
                    readonly property bool on: SettingsService.controlCenter.cards.indexOf(orderCard.modelData) !== -1
                    property real startY: 0

                    height: orderHolder.rowHeight
                    width: orderHolder.width

                    Behavior on y {
                        enabled: !orderCard.dragging

                        NumberAnimation {
                            duration: SettingsConfig.dragReflowAnimMs
                            easing.type: Easing.OutQuad
                        }
                    }

                    Binding {
                        property: "y"
                        target: orderCard
                        value: {
                            var di = -1, ti = -1;
                            for (var i = 0; i < cardRepeater.count; i++) {
                                var it = cardRepeater.itemAt(i);
                                if (it && it.dragging) {
                                    di = it.dragStartIndex;
                                    ti = it.dragTargetIndex;
                                    break;
                                }
                            }
                            var vStep = orderHolder.rowHeight + orderHolder.rowSpacing;
                            var ei = orderCard.index;
                            if (di !== -1 && ti !== -1 && di !== ti) {
                                if (di < ti) {
                                    if (orderCard.index > di && orderCard.index <= ti)
                                        ei = orderCard.index - 1;
                                } else {
                                    if (orderCard.index >= ti && orderCard.index < di)
                                        ei = orderCard.index + 1;
                                }
                            }
                            return ei * vStep;
                        }
                        when: !orderCard.dragging
                    }
                    Rectangle {
                        anchors.fill: parent
                        border.color: orderCard.dragging || dragHandle.containsMouse ? ColorConfig.accent : ColorConfig.textAlpha12
                        border.width: SettingsConfig.hairlineBorderWidth
                        color: orderCard.dragging ? ColorConfig.accentAlpha20 : ColorConfig.textAlpha07
                        opacity: orderCard.on ? 1 : SettingsConfig.dimTextOpacity
                        radius: SettingsConfig.tileRadius

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: SettingsConfig.tileContentMargin
                            anchors.rightMargin: SettingsConfig.tileContentMargin
                            spacing: SettingsConfig.controlCenterCardContentSpacing

                            Item {
                                Layout.fillHeight: true
                                Layout.fillWidth: true

                                MouseArea {
                                    id: dragHandle

                                    anchors.fill: parent
                                    cursorShape: orderCard.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                    hoverEnabled: true

                                    onCanceled: {
                                        preventStealing = false;
                                        orderCard.dragging = false;
                                        orderCard.dragStartIndex = -1;
                                        orderCard.dragTargetIndex = -1;
                                        orderCard.z = 0;
                                    }
                                    onPositionChanged: mouse => {
                                        if (orderCard.dragging) {
                                            var vStep = orderHolder.rowHeight + orderHolder.rowSpacing;
                                            var g = dragHandle.mapToGlobal(mouse.x, mouse.y);
                                            var newY = orderCard.startY + (g.y - orderCard.grabGlobalY);
                                            newY = Math.max(0, Math.min(newY, (cardRepeater.count - 1) * vStep));
                                            orderCard.y = newY;
                                            orderCard.dragTargetIndex = Math.max(0, Math.min(Math.round((newY + orderHolder.rowHeight / 2) / vStep), cardRepeater.count - 1));
                                        }
                                    }
                                    onPressed: mouse => {
                                        var g = dragHandle.mapToGlobal(mouse.x, mouse.y);
                                        orderCard.grabGlobalY = g.y;
                                        orderCard.startY = orderCard.y;
                                        orderCard.dragStartIndex = orderCard.index;
                                        orderCard.dragTargetIndex = orderCard.index;
                                        orderCard.dragging = true;
                                        orderCard.z = 999;
                                        preventStealing = true;
                                    }
                                    onReleased: {
                                        preventStealing = false;
                                        if (orderCard.dragging && orderCard.dragStartIndex !== orderCard.dragTargetIndex)
                                            root.moveCard(orderCard.dragStartIndex, orderCard.dragTargetIndex);
                                        orderCard.dragging = false;
                                        orderCard.dragStartIndex = -1;
                                        orderCard.dragTargetIndex = -1;
                                        orderCard.z = 0;
                                    }
                                }
                                Column {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: SettingsConfig.controlCenterLabelSpacing

                                    Text {
                                        color: ColorConfig.text
                                        elide: Text.ElideRight
                                        font.family: FontConfig.fontFamily
                                        font.pixelSize: FontConfig.fontSettingsBody
                                        text: (root.cardMeta[orderCard.modelData] || {}).label ?? orderCard.modelData
                                        width: parent.width
                                    }
                                    Text {
                                        color: ColorConfig.text
                                        elide: Text.ElideRight
                                        font.family: FontConfig.fontFamily
                                        font.pixelSize: FontConfig.fontSettingsBodySm
                                        opacity: SettingsConfig.hintTextOpacity
                                        text: (root.cardMeta[orderCard.modelData] || {}).hint ?? ""
                                        width: parent.width
                                    }
                                }
                            }
                            Rectangle {
                                color: orderCard.on ? ColorConfig.accent : ColorConfig.textAlpha15
                                height: SettingsConfig.toggleTrackHeight
                                radius: SettingsConfig.toggleTrackRadius
                                width: SettingsConfig.toggleTrackWidth

                                Behavior on color {
                                    ColorAnimation {
                                        duration: SettingsConfig.toggleAnimMs
                                    }
                                }

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: "white"
                                    height: SettingsConfig.toggleKnobSize
                                    radius: SettingsConfig.toggleKnobRadius
                                    width: SettingsConfig.toggleKnobSize
                                    x: orderCard.on ? parent.width - width - SettingsConfig.toggleKnobInset : SettingsConfig.toggleKnobInset

                                    Behavior on x {
                                        NumberAnimation {
                                            duration: SettingsConfig.toggleAnimMs
                                            easing.type: Easing.OutQuad
                                        }
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        if (orderCard.on)
                                            root.disableCard(orderCard.modelData);
                                        else
                                            root.enableCard(orderCard.modelData);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
