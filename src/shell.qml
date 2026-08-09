pragma ComponentBehavior: Bound
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic

import QtQuick
import Quickshell

import qs.bar
import qs.controlcenter
import qs.dock
import qs.idle
import qs.launcher
import qs.lock
import qs.logout
import qs.matrix
import qs.notification
import qs.osd
import qs.settings
import qs.overview
import qs.polkit
import qs.visualizer
import qs.wallpaper

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
