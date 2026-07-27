pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

import qs.service
import qs.config
import qs.modules.core
import qs.modules.lock
import qs.modules.lock.layout

ModuleLoader {
    id: root

    module: "lock"

    sourceComp: Component {
        Scope {
            id: panel

            property alias controller: controller

            signal closeRequested

            Item {
                id: controller

                property string password: ""

                function authenticate(pass) {
                    password = pass;
                    pam.start();
                }
                function close() {
                    sessionLock.beginUnlock();
                }
                function open() {
                    sessionLock.locked = true;
                }

                PamContext {
                    id: pam

                    config: GlobalConfig.pamConfigFile
                    configDirectory: GlobalConfig.pamConfigDir

                    onCompleted: result => {
                        if (result === PamResult.Success) {
                            sessionLock.beginUnlock();
                        } else {
                            controller.password = "";
                            sessionLock.failed = true;
                        }
                    }
                    onPamMessage: {
                        if (this.responseRequired)
                            this.respond(controller.password);
                    }
                }
            }
            WlSessionLock {
                id: sessionLock

                property bool animDoneEmitted: false
                property bool failed: false
                property bool unlocking: false

                function beginUnlock() {
                    unlocking = true;
                    animDoneEmitted = false;
                }

                Binding {
                    property: "locked"
                    target: LockService
                    value: sessionLock.locked
                }
                LockSurface {
                    sessionLock: sessionLock

                    onAuthenticate: pass => controller.authenticate(pass)
                    onClosed: panel.closeRequested()
                }
            }
        }
    }

    IpcHandler {
        function toggle() {
            root.toggle();
        }

        target: "lock"
    }
}
