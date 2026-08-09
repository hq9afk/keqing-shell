pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Item {
    id: root

    property string query: ""
    property var results: []

    function compute() {
        const q = (root.query || "").trim().toLowerCase();
        if (q === "") {
            root.results = [];
            return;
        }

        const allEntries = [...DesktopEntries.applications.values];
        let res = allEntries.filter(d => d.name && d.name.toLowerCase().includes(q));

        res.sort(function (a, b) {
            const an = (a.name || "").toLowerCase();
            const bn = (b.name || "").toLowerCase();

            const aStarts = an.startsWith(q);
            const bStarts = bn.startsWith(q);
            if (aStarts && !bStarts)
                return -1;
            if (bStarts && !aStarts)
                return 1;

            if (an < bn)
                return -1;
            if (an > bn)
                return 1;
            return 0;
        });

        root.results = res;
    }

    Component.onCompleted: compute()
    onQueryChanged: compute()
}
