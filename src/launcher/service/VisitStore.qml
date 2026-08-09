pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import QtQuick.LocalStorage
import Quickshell

Singleton {
    id: root

    property var _countsCache: ({})
    property string _dbDescription: "Keqing launcher visit counts"
    property int _dbEstimatedSize: 1024 * 256
    property string _dbName: "keqing_launcher"
    property string _dbVersion: "1.0"
    property bool _schemaReady: false

    signal changed

    function _ensureSchema() {
        if (root._schemaReady)
            return;
        const db = root._getDb();
        db.transaction(function (tx) {
            tx.executeSql("CREATE TABLE IF NOT EXISTS visits (key TEXT PRIMARY KEY, count INTEGER NOT NULL, last INTEGER NOT NULL)");
        });
        root._schemaReady = true;
    }
    function _getDb() {
        return LocalStorage.openDatabaseSync(root._dbName, root._dbVersion, root._dbDescription, root._dbEstimatedSize);
    }
    function _toKey(entry) {
        if (!entry)
            return "";

        if (entry.path !== undefined && entry.path !== null && String(entry.path) !== "")
            return "file:" + String(entry.path);

        const candidates = [entry.desktopId, entry.id, entry.desktopFile, entry.fileName, entry.exec, entry.command, entry.name];

        for (let i = 0; i < candidates.length; i += 1) {
            const v = candidates[i];
            if (v !== undefined && v !== null) {
                const s = String(v);
                if (s !== "")
                    return "app:" + s;
            }
        }

        return "";
    }
    function getCount(entry) {
        root._ensureSchema();
        const k = root._toKey(entry);
        if (k === "")
            return 0;

        if (root._countsCache[k] !== undefined)
            return Number(root._countsCache[k]) || 0;

        let count = 0;
        const db = root._getDb();
        db.readTransaction(function (tx) {
            const rs = tx.executeSql("SELECT count FROM visits WHERE key = ?", [k]);
            if (rs.rows.length > 0)
                count = Number(rs.rows.item(0).count) || 0;
        });

        root._countsCache[k] = count;
        return count;
    }
    function recordVisit(entry) {
        root._ensureSchema();
        const k = root._toKey(entry);
        if (k === "")
            return;

        const now = Date.now();
        const oldCount = root.getCount(entry);
        const newCount = oldCount + 1;

        const db = root._getDb();
        db.transaction(function (tx) {
            const updated = tx.executeSql("UPDATE visits SET count = ?, last = ? WHERE key = ?", [newCount, now, k]);
            if (updated.rowsAffected === 0)
                tx.executeSql("INSERT INTO visits(key, count, last) VALUES(?, ?, ?)", [k, newCount, now]);
        });

        root._countsCache[k] = newCount;
        root.changed();
    }
}
