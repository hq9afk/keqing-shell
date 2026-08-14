pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.elements
import qs.config
import qs.modules
import qs.service
import qs.settings

ModuleLoader {
    id: root

    module: "settings"

    sourceComp: Component {
        Scope {
            id: panel

            property alias controller: ctrl

            signal closeRequested

            QtObject {
                id: ctrl

                function close() {
                    settingsWindow.close();
                }
                function open() {
                    settingsWindow.open();
                }
            }
            PanelWindow {
                id: settingsWindow

                property bool panelOpen: false
                readonly property list<var> tabDefs: [
                    {
                        label: "Displays",
                        icon: IconConfig.deviceDesktop,
                        component: displaysTabComponent
                    },
                    {
                        label: "Dock",
                        icon: IconConfig.layoutBottombar,
                        component: dockTabComponent
                    },
                    {
                        label: "Idle",
                        icon: IconConfig.moonStars,
                        component: idleTabComponent
                    },
                    {
                        label: "OSD",
                        icon: IconConfig.adjustments,
                        component: osdTabComponent
                    },
                    {
                        label: "Wallpaper",
                        icon: IconConfig.wallpaper,
                        component: wallpaperTabComponent
                    }
                ]

                function close() {
                    settingsWindow.panelOpen = false;
                    closeTimer.start();
                }
                function open() {
                    settingsWindow.visible = true;
                    settingsWindow.panelOpen = true;
                    contentScope.forceActiveFocus();
                }

                WlrLayershell.exclusionMode: ExclusionMode.Ignore
                WlrLayershell.keyboardFocus: settingsWindow.panelOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "keqing-settings"
                anchors.bottom: true
                anchors.left: true
                anchors.right: true
                anchors.top: true
                color: "transparent"
                visible: false

                onClosed: panel.closeRequested()

                Component {
                    id: displaysTabComponent

                    DisplaysTab {}
                }
                Component {
                    id: dockTabComponent

                    DockTab {}
                }
                Component {
                    id: idleTabComponent

                    IdleTab {}
                }
                Component {
                    id: osdTabComponent

                    OSDTab {}
                }
                Component {
                    id: wallpaperTabComponent

                    WallpaperTab {}
                }
                Connections {
                    function onScreensChanged() {
                        closeTimer.stop();
                        settingsWindow.panelOpen = false;
                        settingsWindow.visible = false;
                        settingsWindow.closed();
                    }

                    target: Quickshell
                }
                Timer {
                    id: closeTimer

                    interval: GlobalConfig.animationFast
                    repeat: false

                    onTriggered: {
                        settingsWindow.visible = false;
                        settingsWindow.closed();
                    }
                }
                FocusScope {
                    id: contentScope

                    anchors.fill: parent
                    focus: true

                    Keys.onEscapePressed: event => {
                        settingsWindow.close();
                        event.accepted = true;
                    }

                    MouseArea {
                        anchors.fill: parent

                        onClicked: settingsWindow.close()
                    }
                    Rectangle {
                        id: card

                        anchors.centerIn: parent
                        border.color: ColorConfig.accent
                        border.width: GlobalConfig.borderWidthThick
                        color: ColorConfig.overlay
                        implicitHeight: Math.min(parent.height - SettingsConfig.windowCardHeightInset, SettingsConfig.windowCardMaxHeight)
                        implicitWidth: Math.min(parent.width - SettingsConfig.windowCardWidthInset, SettingsConfig.windowCardMaxWidth)
                        opacity: settingsWindow.panelOpen ? 1.0 : 0.0
                        radius: GlobalConfig.radiusMd
                        scale: settingsWindow.panelOpen ? 1.0 : SettingsConfig.windowCardClosedScale

                        Behavior on opacity {
                            NumberAnimation {
                                duration: GlobalConfig.animationFast
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: GlobalConfig.animationFast
                                easing.type: Easing.OutCubic
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                        }
                        NavRail {
                            id: navRail

                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.top: parent.top
                            expanded: card.width > SettingsConfig.navRailCollapseBreakpoint
                            tabDefs: settingsWindow.tabDefs
                        }
                        RowLayout {
                            anchors.bottom: parent.bottom
                            anchors.left: navRail.right
                            anchors.leftMargin: SettingsConfig.windowRowSpacing
                            anchors.margins: SettingsConfig.windowContentMargins
                            anchors.right: parent.right
                            anchors.top: parent.top
                            spacing: SettingsConfig.windowRowSpacing

                            Rectangle {
                                Layout.fillHeight: true
                                color: ColorConfig.textAlpha08
                                width: SettingsConfig.dividerThickness
                            }
                            ColumnLayout {
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                Layout.leftMargin: SettingsConfig.windowContentLeftMargin
                                spacing: 0

                                Item {
                                    Layout.fillWidth: true
                                    height: SettingsConfig.windowTitleBarHeight

                                    Text {
                                        anchors.centerIn: parent
                                        color: ColorConfig.text
                                        font.family: FontConfig.fontFamily
                                        font.pixelSize: FontConfig.fontSettingsTitle
                                        font.weight: Font.Bold
                                        text: " Settings"
                                    }
                                    Text {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: ColorConfig.text
                                        font.family: IconConfig.fontFamily
                                        font.pixelSize: FontConfig.fontSettingsWindowIcon
                                        opacity: closeHover.containsMouse ? 1.0 : SettingsConfig.windowCloseIconDimmedOpacity
                                        text: IconConfig.close

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: GlobalConfig.animationFast
                                            }
                                        }

                                        MouseArea {
                                            id: closeHover

                                            anchors.fill: parent
                                            anchors.margins: SettingsConfig.windowCloseHitSlop
                                            hoverEnabled: true

                                            onClicked: settingsWindow.close()
                                        }
                                    }
                                }
                                Item {
                                    Layout.preferredHeight: SettingsConfig.windowTitleSpacerHeight
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    color: ColorConfig.textAlpha08
                                    height: SettingsConfig.dividerThickness
                                }
                                Item {
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    Layout.topMargin: SettingsConfig.windowTabTopMargin

                                    Repeater {
                                        model: settingsWindow.tabDefs

                                        delegate: Loader {
                                            id: tabLoader

                                            required property int index
                                            readonly property bool isActive: navRail.currentIndex === tabLoader.index
                                            required property var modelData

                                            active: isActive || item !== null
                                            anchors.fill: parent
                                            enabled: isActive
                                            opacity: isActive ? 1.0 : 0.0
                                            sourceComponent: tabLoader.modelData.component
                                            visible: opacity > 0

                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: GlobalConfig.animationNormal
                                                    easing.type: Easing.OutCubic
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            propagateComposedEvents: true

                            onPressed: mouse => {
                                contentScope.forceActiveFocus();
                                mouse.accepted = false;
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

        target: "settings"
    }
}
