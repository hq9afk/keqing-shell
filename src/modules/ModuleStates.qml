pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick

QtObject {
    id: root

    property var openModules: ({})
    property var openedFromBar: ({})

    function isOpen(name) {
        return !!root.openModules[name];
    }
    function isOpenedFromBarOnScreen(screenName) {
        if (!screenName)
            return false;
        for (var k in root.openedFromBar) {
            if (root.openedFromBar[k] === screenName)
                return true;
        }
        return false;
    }
    function setOpen(name, value) {
        if (!name)
            return;
        var next = Object.assign({}, root.openModules);
        if (value)
            next[name] = true;
        else
            delete next[name];
        root.openModules = next;
    }
    function setOpenedFromBar(name, screenName) {
        if (!name)
            return;
        var next = Object.assign({}, root.openedFromBar);
        if (screenName)
            next[name] = screenName;
        else
            delete next[name];
        root.openedFromBar = next;
    }
}
