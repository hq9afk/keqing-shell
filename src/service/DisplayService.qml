pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

import qs.service

QtObject {
    readonly property var screens: SettingsService.displays

    function _cfg(screen) {
        var def = screens["default"] || {};
        if (!screen)
            return def;
        var entry = screens[screen.name] !== undefined ? screens[screen.name] : screens[screen.model];
        if (entry && entry._enabled !== false)
            return entry;
        return def;
    }
    function showDock(screen) {
        return _cfg(screen).dock !== false;
    }
    function showLock(screen) {
        return _cfg(screen).lock !== false;
    }
    function showNotifications(screen) {
        return _cfg(screen).notifications !== false;
    }
    function showOsd(screen) {
        return _cfg(screen).osd !== false;
    }
}
