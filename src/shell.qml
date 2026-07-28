pragma ComponentBehavior: Bound
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import Quickshell

import qs.modules.bar
import qs.modules.controlcenter
import qs.modules.dock
import qs.modules.idle
import qs.modules.launcher
import qs.modules.lock
import qs.modules.logout
import qs.modules.matrix
import qs.modules.notification
import qs.modules.osd
import qs.modules.settings
import qs.modules.overview
import qs.modules.polkit
import qs.modules.visualizer
import qs.modules.wallpaper

ShellRoot {
    id: root

    // Eager-Loaded Modules
    Bar {}
    Dock {}
    Idle {}
    Notification {}
    OSD {}
    Polkit {}
    Wallpaper {}

    // Lazy-Loaded Modules
    ControlCenter {}
    Launcher {}
    Lock {}
    Logout {}
    Matrix {}
    Overview {}
    Settings {}
    Visualizer {}
}
