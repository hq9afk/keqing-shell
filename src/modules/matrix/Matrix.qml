pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.core
import qs.modules.matrix.layout

ModuleLoader {
    id: root

    module: "matrix"

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
            MatrixWindow {
                id: window

                isOpen: controller.isOpen

                onClosed: panel.closeRequested()
            }
        }
    }

    IpcHandler {
        function toggle() {
            root.toggle();
        }

        target: "matrix"
    }
}
