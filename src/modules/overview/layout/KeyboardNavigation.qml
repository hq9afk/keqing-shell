pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland

import qs.config

Item {
    id: root

    property bool active: false
    readonly property var directionMap: {
        let map = {};
        map[Qt.Key_Left] = [-1, 0];
        map[Qt.Key_Right] = [1, 0];
        map[Qt.Key_Up] = [0, -1];
        map[Qt.Key_Down] = [0, 1];
        return map;
    }
    readonly property var shiftedNumberKeys: {
        let map = {};
        map[Qt.Key_Exclam] = 1;
        map[Qt.Key_At] = 2;
        map[Qt.Key_NumberSign] = 3;
        map[Qt.Key_Dollar] = 4;
        map[Qt.Key_Percent] = 5;
        map[Qt.Key_AsciiCircum] = 6;
        map[Qt.Key_Ampersand] = 7;
        map[Qt.Key_Asterisk] = 8;
        map[Qt.Key_ParenLeft] = 9;
        map[Qt.Key_ParenRight] = 10;
        return map;
    }

    signal requestClearWorkspace(int modifiers)
    signal requestClose
    signal requestSwitchWorkspace(int position, int modifiers)

    Keys.enabled: active
    focus: active
    visible: active

    Keys.onPressed: event => {
        if (!event)
            return;

        const dir = root.directionMap[event.key];
        if (dir) {
            const rows = OverviewConfig.rows;
            const cols = OverviewConfig.columns;
            const currentId = (Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1) - 1;
            const targetCol = ((currentId % cols) + dir[0] + cols) % cols;
            const targetRow = ((Math.floor(currentId / cols)) + dir[1] + rows) % rows;
            const targetId = (targetRow * cols) + targetCol + 1;

            root.requestSwitchWorkspace(targetId, event.modifiers);
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_Escape) {
            root.requestClose();
            event.accepted = true;
            return;
        }

        if (event.key === Qt.Key_D) {
            root.requestClearWorkspace(event.modifiers);
            event.accepted = true;
            return;
        }

        let position = null;
        if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
            position = event.key === Qt.Key_0 ? 10 : event.key - Qt.Key_0;
        } else if (event.modifiers & Qt.ShiftModifier) {
            position = root.shiftedNumberKeys[event.key] || null;
        }

        if (position !== null) {
            root.requestSwitchWorkspace(position, event.modifiers);
            event.accepted = true;
        }
    }
}
