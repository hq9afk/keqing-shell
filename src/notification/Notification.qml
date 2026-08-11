pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

import qs.service
import qs.notification
import qs.config

Variants {
    model: Quickshell.screens

    delegate: Component {
        Scope {
            id: screenScope

            required property var modelData

            PanelWindow {
                id: root

                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "keqing-notifications"
                anchors.bottom: true
                anchors.right: true
                color: "transparent"
                implicitHeight: Math.max(1, stack.implicitHeight)
                implicitWidth: NotificationConfig.cardWidth
                margins.bottom: NotificationConfig.screenMargin
                margins.right: NotificationConfig.screenMargin
                screen: screenScope.modelData
                visible: DisplayService.showNotifications(screenScope.modelData) && NotificationService.popupModel.count > 0

                ColumnLayout {
                    id: stack

                    spacing: NotificationConfig.cardSpacing
                    width: NotificationConfig.cardWidth
                    x: 0
                    y: 0

                    Behavior on implicitHeight {
                        SpringAnimation {
                            damping: 0.4
                            epsilon: 0.01
                            spring: 2.0
                        }
                    }

                    Repeater {
                        model: NotificationService.popupModel

                        delegate: Item {
                            id: card

                            required property string appIcon
                            required property string appName
                            required property string body
                            property bool isDragging: false
                            property bool isHovered: false
                            required property int msTimeout
                            required property int notifId
                            property real opacityValue: NotificationConfig.opacityHidden
                            property real progress: 1.0
                            required property bool removing
                            property real slideOffset: NotificationConfig.cardSlideOffset
                            required property string summary
                            property bool swipeDismissing: false
                            property real swipeX: 0.0
                            property real timeLeft: msTimeout
                            required property var urgency
                            readonly property color urgencyColor: urgency === 2 ? "#e05555" : urgency === 0 ? ColorConfig.textMuted : ColorConfig.accent

                            Layout.fillWidth: true
                            Layout.preferredHeight: cardBg.implicitHeight
                            opacity: opacityValue

                            Behavior on opacityValue {
                                NumberAnimation {
                                    duration: NotificationConfig.animNormal
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on slideOffset {
                                SpringAnimation {
                                    damping: 0.35
                                    epsilon: 0.01
                                    spring: 2.5
                                }
                            }
                            Behavior on swipeX {
                                enabled: !card.isDragging

                                NumberAnimation {
                                    duration: NotificationConfig.animNormal
                                    easing.type: Easing.OutCubic
                                }
                            }
                            transform: [
                                Translate {
                                    x: card.swipeX
                                    y: card.slideOffset
                                }
                            ]

                            Component.onCompleted: {
                                slideOffset = 0;
                                opacityValue = NotificationConfig.opacityVisible;
                            }
                            onRemovingChanged: {
                                if (!removing)
                                    return;
                                opacityValue = NotificationConfig.opacityHidden;
                                if (swipeDismissing) {
                                    swipeX = NotificationConfig.cardWidth + NotificationConfig.cardSwipeExitOffset;
                                } else {
                                    swipeX = 0;
                                    slideOffset = NotificationConfig.cardSlideOffset;
                                }
                                exitTimer.start();
                            }

                            Timer {
                                id: exitTimer

                                interval: NotificationConfig.animNormal + NotificationConfig.animExitBuffer

                                onTriggered: NotificationService.finishDismiss(card.notifId)
                            }
                            Timer {
                                interval: NotificationConfig.progressTickInterval
                                repeat: true
                                running: card.msTimeout > 0 && !card.isHovered && !card.removing && card.timeLeft > 0

                                onTriggered: {
                                    card.timeLeft = Math.max(0, card.timeLeft - NotificationConfig.progressTickInterval);
                                    card.progress = card.timeLeft / card.msTimeout;
                                    if (card.timeLeft <= 0)
                                        NotificationService.startDismiss(card.notifId);
                                }
                            }
                            Rectangle {
                                id: cardBg

                                border.color: ColorConfig.accent
                                border.width: NotificationConfig.cardBorderWidth
                                color: ColorConfig.overlay
                                implicitHeight: cardContent.implicitHeight + NotificationConfig.cardPadding * 2 + NotificationConfig.cardExtraHeight
                                radius: NotificationConfig.cardRadius
                                width: parent.width

                                Item {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    clip: true
                                    height: NotificationConfig.progressBarHeight

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        color: card.urgencyColor
                                        height: parent.height + cardBg.radius
                                        opacity: NotificationConfig.progressTrackOpacity
                                        radius: cardBg.radius
                                    }
                                    Rectangle {
                                        anchors.right: parent.right
                                        color: card.urgencyColor
                                        height: parent.height + cardBg.radius
                                        radius: cardBg.radius
                                        width: parent.width * card.progress

                                        Behavior on width {
                                            NumberAnimation {
                                                duration: NotificationConfig.progressBarFillDuration
                                                easing.type: Easing.Linear
                                            }
                                        }
                                    }
                                }
                                Column {
                                    id: cardContent

                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: NotificationConfig.cardContentSpacing
                                    width: parent.width - NotificationConfig.cardPadding - closeHitArea.width - NotificationConfig.cardContentTrailingGap
                                    x: NotificationConfig.cardPadding

                                    Row {
                                        spacing: NotificationConfig.headerRowSpacing
                                        width: parent.width

                                        Rectangle {
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: card.urgencyColor
                                            height: NotificationConfig.urgencyDotSize
                                            radius: NotificationConfig.urgencyDotRadius
                                            width: NotificationConfig.urgencyDotSize
                                        }
                                        Text {
                                            color: ColorConfig.text
                                            elide: Text.ElideRight
                                            font.family: FontConfig.fontFamily
                                            font.pixelSize: NotificationConfig.fontAppName
                                            font.weight: Font.Bold
                                            opacity: NotificationConfig.opacityAppNameDim
                                            text: card.appName || "Notification"
                                            width: Math.min(implicitWidth, parent.width - NotificationConfig.appNameMaxWidthInset)
                                        }
                                    }
                                    Text {
                                        color: ColorConfig.text
                                        elide: Text.ElideRight
                                        font.family: FontConfig.fontFamily
                                        font.pixelSize: NotificationConfig.fontSummary
                                        font.weight: Font.DemiBold
                                        maximumLineCount: 2
                                        text: card.summary
                                        visible: text.length > 0
                                        width: parent.width
                                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                    }
                                    Text {
                                        color: ColorConfig.text
                                        elide: Text.ElideRight
                                        font.family: FontConfig.fontFamily
                                        font.pixelSize: NotificationConfig.fontBody
                                        maximumLineCount: 3
                                        opacity: NotificationConfig.opacityBodyDim
                                        text: card.body
                                        visible: text.length > 0
                                        width: parent.width
                                        wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                    }
                                }
                                Item {
                                    id: closeHitArea

                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    height: NotificationConfig.closeHitAreaSize
                                    width: NotificationConfig.closeHitAreaSize

                                    Text {
                                        id: closeIcon

                                        anchors.centerIn: parent
                                        color: ColorConfig.text
                                        font.family: IconConfig.fontFamily
                                        font.pixelSize: FontConfig.fontNotificationClose
                                        opacity: closeHover.containsMouse ? NotificationConfig.opacityVisible : NotificationConfig.closeIconOpacityIdle
                                        text: IconConfig.close

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: NotificationConfig.animFast
                                            }
                                        }
                                    }
                                    MouseArea {
                                        id: closeHover

                                        anchors.fill: parent
                                        hoverEnabled: true

                                        onClicked: NotificationService.startDismiss(card.notifId)
                                    }
                                }
                                HoverHandler {
                                    onHoveredChanged: card.isHovered = hovered
                                }
                                MouseArea {
                                    id: cardMouse

                                    property real pressX: 0

                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    anchors.fill: parent
                                    z: -1

                                    onCanceled: {
                                        card.isDragging = false;
                                        card.swipeX = 0;
                                    }
                                    onPositionChanged: mouse => {
                                        if (!card.isDragging || card.removing)
                                            return;
                                        var delta = mouse.x - pressX;
                                        if (delta > 0)
                                            card.swipeX = delta;
                                    }
                                    onPressed: mouse => {
                                        card.isDragging = true;
                                        pressX = mouse.x;
                                    }
                                    onReleased: mouse => {
                                        card.isDragging = false;
                                        if (mouse.button === Qt.RightButton) {
                                            NotificationService.startDismiss(card.notifId);
                                            return;
                                        }
                                        if (card.swipeX > NotificationConfig.cardSwipeDismissThreshold) {
                                            card.swipeDismissing = true;
                                            NotificationService.startDismiss(card.notifId);
                                        } else if (card.swipeX > 0) {
                                            card.swipeX = 0;
                                        } else {
                                            NotificationService.invokeAction(card.notifId, "default");
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
}
