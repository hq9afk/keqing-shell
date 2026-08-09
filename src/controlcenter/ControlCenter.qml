pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.core
import qs.controlcenter.layout

ModuleLoader {
    id: root

    module: "controlcenter"

    sourceComp: Component {
        Scope {
            id: panel

            property alias controller: controller

            signal closeRequested

            // Controller
            Item {
                id: controller

                property bool isOpen: false

                function close() {
                    isOpen = false;
                }
                function open() {
                    isOpen = true;
                }
                function toggle() {
                    if (isOpen)
                        close();
                    else
                        open();
                }
            }

            // Window
            ControlCenterWindow {
                id: window

                isOpen: controller.isOpen

                onClosed: panel.closeRequested()
                onDismissRequested: controller.close()
            }
        }
    }

    IpcHandler {
        function toggle() {
            root.toggle();
        }

        target: "controlcenter"
    }
}
