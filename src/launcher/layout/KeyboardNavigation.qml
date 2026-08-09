pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property bool active: false
    property var launcherRef

    signal requestClose
    signal requestLaunch(bool shift)
    signal requestMove(int delta, bool shift)

    Keys.enabled: active
    Keys.priority: Keys.BeforeItem
    visible: active

    Keys.onPressed: event => {
        if (!event)
            return;

        const shift = !!(event.modifiers & Qt.ShiftModifier);
        let handled = true;

        switch (event.key) {
        case Qt.Key_Up:
            root.requestMove(-1, shift);
            break;
        case Qt.Key_Down:
            root.requestMove(1, shift);
            break;
        case Qt.Key_Enter:
        case Qt.Key_Return:
            root.requestLaunch(shift);
            break;
        case Qt.Key_Escape:
            root.requestClose();
            break;
        default:
            handled = false;
        }

        if (handled)
            event.accepted = true;
    }
}
