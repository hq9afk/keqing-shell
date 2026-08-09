pragma ComponentBehavior: Bound

import QtQuick

import qs.components
import qs.service
import qs.lock
import qs.config

Rectangle {
    id: root

    required property bool failed
    readonly property int fullHeight: mainCol.implicitHeight + 2 * LockConfig.panelMargin

    // Full content size — evaluated at animation start (scale: 0 doesn't affect implicit size)
    readonly property int fullWidth: mainCol.implicitWidth + 2 * LockConfig.panelMargin

    // Compact square sized to wrap the lock icon
    readonly property int iconBoxSize: lockIcon.font.pixelSize + LockConfig.panelMargin * 4
    required property bool unlocking

    signal authenticate(string pass)
    signal failedReset
    signal unlockFinished

    border.color: ColorConfig.accent
    border.width: LockConfig.bgBorderWidth
    clip: true
    color: ColorConfig.overlay
    implicitHeight: iconBoxSize
    implicitWidth: iconBoxSize
    radius: LockConfig.panelRadius
    scale: LockConfig.scaleHidden

    Component.onCompleted: initAnim.start()
    onUnlockingChanged: if (root.unlocking)
        unlockAnim.start()

    Text {
        id: lockIcon

        anchors.centerIn: parent
        color: ColorConfig.accent
        font.family: IconConfig.fontFamily
        font.pixelSize: LockConfig.fontIcon
        opacity: LockConfig.opacityVisible
        text: root.unlocking ? IconConfig.lockOpen : IconConfig.lock
    }
    Column {
        id: mainCol

        anchors.centerIn: parent
        clip: true
        opacity: LockConfig.opacityHidden
        scale: LockConfig.scaleHidden

        // Clock
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            color: "transparent"
            implicitHeight: dateTimeCol.implicitHeight
            implicitWidth: dateTimeCol.implicitWidth

            Column {
                id: dateTimeCol

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: ColorConfig.text
                    font.family: FontConfig.fontFamily
                    font.pixelSize: LockConfig.fontTime
                    text: Qt.formatDateTime(DateTimeService.date, "hh:mm")
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: ColorConfig.text
                    font.family: FontConfig.fontFamily
                    font.pixelSize: LockConfig.fontDate
                    text: Qt.formatDateTime(DateTimeService.date, "dddd, MMM dd yyyy")
                }
            }
        }
        Space {
            height: LockConfig.panelGapClockAvatar
        }

        // Avatar
        RoundImage {
            anchors.horizontalCenter: parent.horizontalCenter
            bgColor: ColorConfig.fieldBg
            borderColor: ColorConfig.accent
            borderWidth: LockConfig.profileBorderWidth
            implicitHeight: LockConfig.profileSize
            implicitWidth: LockConfig.profileSize
            source: GlobalConfig.userPfp
        }
        Space {
            height: LockConfig.panelGapAvatarUsername
        }

        // Username
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: ColorConfig.text
            font.family: FontConfig.fontFamily
            font.pixelSize: LockConfig.fontNormal
            text: GlobalConfig.user
        }
        Space {
            height: LockConfig.panelGapUsernameInput
        }

        // Password input
        PasswordInput {
            id: passwordField

            anchors.horizontalCenter: parent.horizontalCenter
            animFastMs: LockConfig.animFastMs
            animNormalMs: LockConfig.animNormalMs
            border.color: ColorConfig.accent
            border.width: LockConfig.bgBorderWidth
            color: ColorConfig.fieldBg
            dotContainerMargin: LockConfig.bgRadius
            dotSize: LockConfig.dotSize
            dotSlideOffset: LockConfig.dotSlideOffset
            failText: "Skill Issue"
            failed: root.failed
            focus: true
            fontSize: LockConfig.fontNormal
            height: LockConfig.inputHeight
            keepFocus: true
            radius: LockConfig.inputRadius
            width: LockConfig.inputWidth

            onAccepted: {
                root.authenticate(text);
                clear();
            }
            onTextChanged: root.failedReset()
        }
        Space {
            height: LockConfig.panelGapInputMessage
        }

        // Motivational text
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            color: ColorConfig.accentAlt
            font.family: FontConfig.fontFamily
            font.pixelSize: LockConfig.fontNormal
            text: "Come on. Enough procrastinating. Let's go."
        }
    }

    // Phase 1: panel + lock icon spin in together (full 360°, scale 0→1)
    // Phase 2: card expands, lock icon fades out, content scales/fades in
    SequentialAnimation {
        id: initAnim

        ParallelAnimation {
            NumberAnimation {
                duration: LockConfig.animSpinMs
                easing.overshoot: 0.6
                easing.type: Easing.OutBack
                from: LockConfig.scaleHidden
                property: "scale"
                target: root
                to: LockConfig.scaleFull
            }
            NumberAnimation {
                duration: LockConfig.animSpinMs
                easing.type: Easing.InOutCubic
                from: 0
                property: "rotation"
                target: root
                to: 360
            }
        }
        ParallelAnimation {
            NumberAnimation {
                duration: LockConfig.animExpandMs
                easing.type: Easing.OutCubic
                property: "implicitWidth"
                target: root
                to: root.fullWidth
            }
            NumberAnimation {
                duration: LockConfig.animExpandMs
                easing.type: Easing.OutCubic
                property: "implicitHeight"
                target: root
                to: root.fullHeight
            }
            NumberAnimation {
                duration: LockConfig.animIconFadeOutMs
                easing.type: Easing.OutCubic
                property: "opacity"
                target: lockIcon
                to: LockConfig.opacityHidden
            }
            NumberAnimation {
                duration: LockConfig.animContentFadeInMs
                easing.type: Easing.OutCubic
                property: "opacity"
                target: mainCol
                to: LockConfig.opacityVisible
            }
            NumberAnimation {
                duration: LockConfig.animContentScaleInMs
                easing.overshoot: 0.5
                easing.type: Easing.OutBack
                property: "scale"
                target: mainCol
                to: LockConfig.scaleFull
            }
        }
    }

    // Reverse of initAnim: fade out content → restore icon, then spin + shrink panel
    SequentialAnimation {
        id: unlockAnim

        onFinished: root.unlockFinished()

        ParallelAnimation {
            NumberAnimation {
                duration: LockConfig.animShrinkMs
                easing.type: Easing.InCubic
                property: "implicitWidth"
                target: root
                to: root.iconBoxSize
            }
            NumberAnimation {
                duration: LockConfig.animShrinkMs
                easing.type: Easing.InCubic
                property: "implicitHeight"
                target: root
                to: root.iconBoxSize
            }
            NumberAnimation {
                duration: LockConfig.animIconFadeInMs
                easing.type: Easing.InCubic
                property: "opacity"
                target: lockIcon
                to: LockConfig.opacityVisible
            }
            NumberAnimation {
                duration: LockConfig.animContentFadeOutMs
                easing.type: Easing.InCubic
                property: "opacity"
                target: mainCol
                to: LockConfig.opacityHidden
            }
            NumberAnimation {
                duration: LockConfig.animContentScaleOutMs
                easing.overshoot: 0.5
                easing.type: Easing.InBack
                property: "scale"
                target: mainCol
                to: LockConfig.scaleHidden
            }
        }
        ParallelAnimation {
            NumberAnimation {
                duration: LockConfig.animSpinMs
                easing.overshoot: 0.6
                easing.type: Easing.InBack
                property: "scale"
                target: root
                to: LockConfig.scaleHidden
            }
            NumberAnimation {
                duration: LockConfig.animSpinMs
                easing.type: Easing.InOutCubic
                from: 0
                property: "rotation"
                target: root
                to: -360
            }
        }
    }
}
