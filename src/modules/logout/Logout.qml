pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.components
import qs.service
import qs.modules.core
import qs.modules.logout
import qs.config

ModuleLoader {
    id: root

    module: "logout"

    sourceComp: Component {
        Scope {
            id: panel

            property alias controller: controller

            signal closeRequested

            // Controller
            Item {
                id: controller

                readonly property var chars: {
                    var btns = SettingsService.powerButtons;
                    if (btns && btns.length > 0)
                        return btns.map(function (b) {
                            return b.char || "";
                        });
                    return LogoutConfig.actionsChars;
                }
                readonly property var command: {
                    var btns = SettingsService.powerButtons;
                    if (btns && btns.length > 0)
                        return btns.map(function (b) {
                            return b.cmd || "";
                        });
                    return LogoutConfig.actionsCommands;
                }
                property bool isOpen: false

                signal executed(int index)

                function close(fast) {
                    isOpen = false;
                    if (fast === true) {
                        animation.fastHide();
                        panel.closeRequested();
                    } else {
                        animation.start("out");
                    }
                }
                function exec(index) {
                    if (index === undefined || index === null)
                        return;
                    const i = Number(index);
                    if (Number.isNaN(i) || i < 0 || i >= command.length)
                        return;
                    const cmd = command[i];
                    if (!cmd || !cmd.trim())
                        return;
                    Quickshell.execDetached(["bash", "-c", cmd]);
                    executed(i);
                    close(true);
                }
                function open() {
                    isOpen = true;
                    animation.start("in");
                }
                function toggle() {
                    if (isOpen)
                        close(false);
                    else
                        open();
                }
            }

            // Window
            PanelWindow {
                id: window

                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
                WlrLayershell.layer: WlrLayer.Overlay
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                visible: false

                onClosed: panel.closeRequested()
                onVisibleChanged: {
                    if (visible)
                        keyHandler.forceActiveFocus();
                }

                anchors {
                    bottom: true
                    left: true
                    right: true
                    top: true
                }

                // Keyboard navigation
                Item {
                    id: keyHandler

                    property bool acceptInput: false

                    Keys.enabled: window.visible
                    Keys.priority: Keys.BeforeItem
                    anchors.fill: parent
                    focus: window.visible
                    visible: window.visible

                    Keys.onPressed: event => {
                        if (!event)
                            return;
                        event.accepted = true;
                        if (!acceptInput)
                            return;
                        let handled = true;
                        switch (event.key) {
                        case Qt.Key_Escape:
                            controller.close(false);
                            break;
                        case Qt.Key_Left:
                            buttons.move(-1);
                            break;
                        case Qt.Key_Right:
                            buttons.move(1);
                            break;
                        case Qt.Key_Return:
                        case Qt.Key_Enter:
                            buttons.exec(buttons.currentIndex);
                            break;
                        default:
                            handled = false;
                        }
                        if (handled)
                            return;
                        if (event.key >= Qt.Key_1 && event.key <= Qt.Key_8)
                            buttons.setIndex(event.key - Qt.Key_1);
                        else
                            buttons.setIndex(0);
                    }
                }

                // Outside click dismiss
                MouseArea {
                    acceptedButtons: Qt.LeftButton
                    anchors.fill: parent
                    enabled: window.visible
                    hoverEnabled: true

                    onClicked: {
                        if (!buttons.containsMouse())
                            controller.close(false);
                    }
                }

                // Buttons + logo
                Item {
                    anchors.centerIn: parent

                    Repeater {
                        id: buttons

                        property int currentIndex: 0
                        property bool highlightEnabled: true

                        function containsMouse() {
                            for (var i = 0; i < count; ++i) {
                                var c = itemAt(i);
                                if (c && c.isMouseHovered)
                                    return true;
                            }
                            return false;
                        }
                        function exec(i) {
                            controller.exec(i);
                        }
                        function move(i) {
                            currentIndex = (currentIndex + i + LogoutConfig.buttonsCount) % LogoutConfig.buttonsCount;
                        }
                        function setIndex(i) {
                            currentIndex = i;
                        }

                        model: LogoutConfig.buttonsCount
                        z: 1

                        delegate: LogoutButton {
                            chars: controller.chars
                            currentIndex: buttons.currentIndex
                            highlightEnabled: buttons.highlightEnabled
                            keyInputActive: keyHandler.acceptInput

                            onExecRequested: idx => controller.exec(idx)
                        }
                    }
                    RoundImage {
                        id: logo

                        anchors.centerIn: parent
                        bgColor: ColorConfig.fieldBg
                        borderColor: ColorConfig.accent
                        borderWidth: LogoutConfig.logoBorderWidth
                        height: LogoutConfig.logoSize
                        scale: 0
                        source: window.visible ? GlobalConfig.logoutLogo : ""
                        width: LogoutConfig.logoSize
                    }
                }

                // Animations
                Item {
                    id: animation

                    property string currentState: ""

                    function fastHide() {
                        stopIn();
                        stopOut();
                        window.visible = false;
                        keyHandler.acceptInput = false;
                        logo.scale = 0;
                        resetButtons(false);
                        currentState = "";
                    }
                    function resetButtons(toVisible) {
                        for (let j = 0; j < buttons.count; ++j) {
                            buttons.itemAt(j).setExpanded(toVisible);
                        }
                    }
                    function start(state) {
                        if (state === currentState)
                            return;
                        switch (state) {
                        case "in":
                            stopOut();
                            startIn();
                            break;
                        case "out":
                            stopIn();
                            startOut();
                            break;
                        }
                    }
                    function startIn() {
                        logo.scale = 0;
                        resetButtons(false);
                        buttons.highlightEnabled = false;
                        buttons.setIndex(0);
                        keyHandler.acceptInput = false;
                        currentState = "in";
                        allIn.start();
                    }
                    function startOut() {
                        logo.scale = 1;
                        buttons.highlightEnabled = false;
                        resetButtons(true);
                        keyHandler.acceptInput = false;
                        currentState = "out";
                        allOut.start();
                    }
                    function stopIn() {
                        allIn.stop();
                        buttonIn.stop();
                        buttonIn.i = 0;
                    }
                    function stopOut() {
                        allOut.stop();
                        buttonOut.stop();
                        buttonOut.i = buttons.count - 1;
                    }

                    Timer {
                        id: buttonIn

                        property int i: 0

                        interval: LogoutConfig.buttonsStaggerMs
                        repeat: true

                        onTriggered: {
                            if (i < buttons.count) {
                                buttons.itemAt(i).setExpanded(true);
                                i++;
                            } else {
                                stop();
                                i = 0;
                            }
                        }
                    }
                    Timer {
                        id: buttonOut

                        property int i: buttons.count - 1

                        interval: LogoutConfig.buttonsStaggerMs
                        repeat: true

                        onTriggered: {
                            if (i >= 0) {
                                buttons.itemAt(i).setExpanded(false);
                                i--;
                            } else {
                                stop();
                                i = buttons.count - 1;
                            }
                        }
                    }
                    SequentialAnimation {
                        id: allIn

                        running: false

                        ScriptAction {
                            script: window.visible = true
                        }
                        ScriptAction {
                            script: logo.reset()
                        }
                        NumberAnimation {
                            duration: LogoutConfig.logoAnimMs
                            easing.type: Easing.OutBack
                            from: 0
                            properties: "scale"
                            target: logo
                            to: 1
                        }
                        ScriptAction {
                            script: buttonIn.start()
                        }
                        PauseAnimation {
                            duration: buttons.count * LogoutConfig.buttonsStaggerMs
                        }
                        ScriptAction {
                            script: {
                                buttons.highlightEnabled = true;
                                keyHandler.acceptInput = true;
                            }
                        }
                    }
                    SequentialAnimation {
                        id: allOut

                        running: false

                        ScriptAction {
                            script: keyHandler.acceptInput = false
                        }
                        ScriptAction {
                            script: buttonOut.start()
                        }
                        PauseAnimation {
                            duration: buttons.count * LogoutConfig.buttonsStaggerMs
                        }
                        NumberAnimation {
                            duration: LogoutConfig.logoAnimMs
                            easing.type: Easing.InBack
                            from: 1
                            properties: "scale"
                            target: logo
                            to: 0
                        }
                        ScriptAction {
                            script: {
                                window.visible = false;
                                animation.currentState = "";
                                logo.stop();
                                window.closed();
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        function toggle() {
            root.toggle();
        }

        target: "logout"
    }
}
