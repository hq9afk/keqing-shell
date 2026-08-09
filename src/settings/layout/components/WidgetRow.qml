pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.service
import qs.settings
import qs.config

Column {
    id: root

    property string screenName: "default"
    property string section: ""
    readonly property var validWidgets: ["Battery", "Bluetooth", "Clock", "ControlCenter", "Custom", "Dock", "Network", "Power", "SystemMonitor", "Tray", "Volume", "Workspace"]
    readonly property var widgetModel: {
        var all = SettingsService.allWidgets;
        var entry = all[screenName] || all["default"] || SettingsService._defaultWidgets;
        return entry[section] || [];
    }

    function addWidget(widgetId) {
        var a = root.widgetModel.slice();
        a.push({
            id: widgetId
        });
        SettingsService.setWidgets(root.screenName, root.section, a);
    }
    function hasSettings(widgetId) {
        return widgetId === "Custom" || widgetId === "Clock" || widgetId === "Tray" || widgetId === "Power";
    }
    function moveWidget(from, to) {
        if (from === to || to < 0 || to >= root.widgetModel.length)
            return;
        var a = root.widgetModel.slice();
        var item = a.splice(from, 1)[0];
        a.splice(to, 0, item);
        SettingsService.setWidgets(root.screenName, root.section, a);
    }
    function removeWidget(idx) {
        var a = root.widgetModel.slice();
        a.splice(idx, 1);
        SettingsService.setWidgets(root.screenName, root.section, a);
    }

    spacing: SettingsConfig.widgetRowSpacing

    Text {
        color: ColorConfig.text
        font.family: FontConfig.fontFamily
        font.pixelSize: FontConfig.fontSettingsBody
        opacity: SettingsConfig.dimTextOpacity
        text: root.section.charAt(0).toUpperCase() + root.section.slice(1)
    }
    Item {
        id: cardHolder

        property int cardHeight: SettingsConfig.widgetCardHeight
        property int cardSpacing: SettingsConfig.reorderItemSpacing
        readonly property int cardWidth: SettingsConfig.widgetCardWidth
        readonly property int columns: SettingsConfig.widgetGridColumns
        property int rowSpacing: SettingsConfig.reorderItemSpacing

        height: Math.max(cardHeight, Math.ceil(Math.max(1, cardRepeater.count) / columns) * (cardHeight + rowSpacing) - rowSpacing)
        width: root.width

        Repeater {
            id: cardRepeater

            model: root.widgetModel

            delegate: Item {
                id: wCard

                property int dragStartIndex: -1
                property int dragTargetIndex: -1
                property bool dragging: false
                property real grabGlobalX: 0
                property real grabGlobalY: 0
                required property int index
                required property var modelData
                property real startX: 0
                property real startY: 0

                height: cardHolder.cardHeight
                width: cardHolder.cardWidth

                Behavior on x {
                    enabled: !wCard.dragging

                    NumberAnimation {
                        duration: SettingsConfig.dragReflowAnimMs
                        easing.type: Easing.OutQuad
                    }
                }
                Behavior on y {
                    enabled: !wCard.dragging

                    NumberAnimation {
                        duration: SettingsConfig.dragReflowAnimMs
                        easing.type: Easing.OutQuad
                    }
                }

                Binding {
                    property: "x"
                    target: wCard
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
                        var cols = cardHolder.columns;
                        var hStep = cardHolder.cardWidth + cardHolder.cardSpacing;
                        var ei = wCard.index;
                        if (di !== -1 && ti !== -1 && di !== ti) {
                            var ci = wCard.index;
                            if (di < ti) {
                                if (ci > di && ci <= ti)
                                    ei = ci - 1;
                            } else {
                                if (ci >= ti && ci < di)
                                    ei = ci + 1;
                            }
                        }
                        return (ei % cols) * hStep;
                    }
                    when: !wCard.dragging
                }
                Binding {
                    property: "y"
                    target: wCard
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
                        var cols = cardHolder.columns;
                        var vStep = cardHolder.cardHeight + cardHolder.rowSpacing;
                        var ei = wCard.index;
                        if (di !== -1 && ti !== -1 && di !== ti) {
                            var ci = wCard.index;
                            if (di < ti) {
                                if (ci > di && ci <= ti)
                                    ei = ci - 1;
                            } else {
                                if (ci >= ti && ci < di)
                                    ei = ci + 1;
                            }
                        }
                        return Math.floor(ei / cols) * vStep;
                    }
                    when: !wCard.dragging
                }
                Rectangle {
                    id: cardBg

                    anchors.fill: parent
                    border.color: wCard.dragging || dragHandle.containsMouse ? ColorConfig.accent : ColorConfig.textAlpha12
                    border.width: SettingsConfig.hairlineBorderWidth
                    color: wCard.dragging ? ColorConfig.accentAlpha20 : ColorConfig.textAlpha07
                    radius: SettingsConfig.widgetCardRadius

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: SettingsConfig.widgetCardContentMargin
                        anchors.rightMargin: SettingsConfig.widgetCardContentMargin
                        spacing: SettingsConfig.widgetCardContentSpacing

                        Item {
                            Layout.fillHeight: true
                            Layout.fillWidth: true

                            MouseArea {
                                id: dragHandle

                                anchors.fill: parent
                                cursorShape: wCard.dragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                hoverEnabled: true

                                onCanceled: {
                                    preventStealing = false;
                                    wCard.dragging = false;
                                    wCard.dragStartIndex = -1;
                                    wCard.dragTargetIndex = -1;
                                    wCard.z = 0;
                                }
                                onPositionChanged: mouse => {
                                    if (wCard.dragging) {
                                        var cols = cardHolder.columns;
                                        var hStep = cardHolder.cardWidth + cardHolder.cardSpacing;
                                        var vStep = cardHolder.cardHeight + cardHolder.rowSpacing;
                                        var maxRows = Math.ceil(cardRepeater.count / cols);
                                        var g = dragHandle.mapToGlobal(mouse.x, mouse.y);
                                        var newX = wCard.startX + (g.x - wCard.grabGlobalX);
                                        var newY = wCard.startY + (g.y - wCard.grabGlobalY);
                                        newX = Math.max(0, Math.min(newX, (cols - 1) * hStep));
                                        newY = Math.max(0, Math.min(newY, (maxRows - 1) * vStep));
                                        wCard.x = newX;
                                        wCard.y = newY;
                                        var col = Math.round((newX + cardHolder.cardWidth / 2) / hStep);
                                        var row = Math.round((newY + cardHolder.cardHeight / 2) / vStep);
                                        col = Math.max(0, Math.min(col, cols - 1));
                                        row = Math.max(0, Math.min(row, maxRows - 1));
                                        wCard.dragTargetIndex = Math.max(0, Math.min(row * cols + col, cardRepeater.count - 1));
                                    }
                                }
                                onPressed: mouse => {
                                    var g = dragHandle.mapToGlobal(mouse.x, mouse.y);
                                    wCard.grabGlobalX = g.x;
                                    wCard.grabGlobalY = g.y;
                                    wCard.startX = wCard.x;
                                    wCard.startY = wCard.y;
                                    wCard.dragStartIndex = wCard.index;
                                    wCard.dragTargetIndex = wCard.index;
                                    wCard.dragging = true;
                                    wCard.z = 999;
                                    preventStealing = true;
                                }
                                onReleased: {
                                    preventStealing = false;
                                    if (wCard.dragging && wCard.dragStartIndex !== wCard.dragTargetIndex)
                                        root.moveWidget(wCard.dragStartIndex, wCard.dragTargetIndex);
                                    wCard.dragging = false;
                                    wCard.dragStartIndex = -1;
                                    wCard.dragTargetIndex = -1;
                                    wCard.z = 0;
                                }
                            }
                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 0
                                color: ColorConfig.text
                                elide: Text.ElideRight
                                font.family: FontConfig.fontFamily
                                font.pixelSize: FontConfig.fontSettingsBody
                                text: wCard.modelData.id ?? ""
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                        Text {
                            color: ColorConfig.text
                            font.family: IconConfig.fontFamily
                            font.pixelSize: FontConfig.fontSettingsBody
                            opacity: settingsBtn.containsMouse ? 1.0 : SettingsConfig.faintOpacity
                            text: IconConfig.settings
                            visible: root.hasSettings(wCard.modelData.id ?? "")

                            MouseArea {
                                id: settingsBtn

                                anchors.fill: parent
                                anchors.margins: SettingsConfig.widgetRemoveHitSlop
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                onClicked: widgetSettingsPopup.openForCard(wCard.index, wCard.modelData)
                            }
                        }
                        Text {
                            color: ColorConfig.text
                            font.family: IconConfig.fontFamily
                            font.pixelSize: FontConfig.fontSettingsBody
                            opacity: removeBtn.containsMouse ? 1.0 : SettingsConfig.faintOpacity
                            text: IconConfig.close

                            MouseArea {
                                id: removeBtn

                                anchors.fill: parent
                                anchors.margins: SettingsConfig.widgetRemoveHitSlop
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                onClicked: root.removeWidget(wCard.index)
                            }
                        }
                    }
                }
            }
        }
    }
    WidgetSettingsPopup {
        id: widgetSettingsPopup

        screenName: root.screenName
        section: root.section

        onAboutToHide: SettingsService.widgetPopupOpen = false
        onAboutToShow: SettingsService.widgetPopupOpen = true
    }
    ComboBox {
        model: root.validWidgets
        placeholder: "Add widget…"
        width: root.width

        onItemSelected: value => root.addWidget(value)
    }
}
