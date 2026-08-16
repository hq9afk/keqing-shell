pragma ComponentBehavior: Bound

import Quickshell

Scope {
    id: panel

    property alias controller: controller

    signal closeRequested

    Controller {
        id: controller

        browseRef: window.browseRef

        onCloseRequested: panel.closeRequested()
    }
    Window {
        id: window

        launcherRef: controller
    }
}
