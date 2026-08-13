pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

import qs.components
import qs.config
import qs.core
import qs.launcher
import qs.service

ModuleLoader {
    id: launcherRoot

    module: "launcher"

    sourceComp: Component {
        Scope {
            id: panel

            property alias controller: controller

            signal closeRequested

            LauncherController {
                id: controller

                browseRef: window.browseRef

                onCloseRequested: panel.closeRequested()
            }
            LauncherWindow {
                id: window

                launcherRef: controller
                mode: controller.mode || LauncherConfig.modeDrun
                resultsModel: controller.resultsModel
                visible: controller.isOpen

                onDismissRequested: controller.goBack()
                onEntryActivated: controller.launch(modelData)
                onQueryEdited: text => controller.query = text
            }
        }
    }

    IpcHandler {
        function toggle() {
            launcherRoot.toggle(false);
        }
        function toggleGlobal() {
            launcherRoot.toggle(true);
        }

        target: "launcher"
    }

    component LauncherController: Item {
        id: ctrl

        property string baseMode: LauncherConfig.modeDrun
        property var browseRef: null
        property string effectiveQuery: ""
        property bool isOpen: false
        property var mode: null
        property string query: ""
        property var resultsModel: directoryBrowser.active ? directoryBrowser.results : filtered.values
        property string searchRoot: Quickshell.env("HOME")
        readonly property bool subMenuOpen: directoryBrowser.active

        signal closeRequested

        function close(resetInput) {
            directoryBrowser.close();
            if (resetInput === undefined || resetInput) {
                if (ctrl.browseRef && ctrl.browseRef.input)
                    ctrl.browseRef.input.text = "";
            }

            ctrl.resetSelection();
            ctrl.effectiveQuery = "";
            ctrl.mode = null;
            ctrl.isOpen = false;
            ctrl.closeRequested();
        }
        function currentModelData() {
            var current = (ctrl.browseRef && ctrl.browseRef.list) ? ctrl.browseRef.list.currentItem : null;
            return (current && current.modelData) ? current.modelData : null;
        }
        function detectModeAndQuery(raw) {
            const src = String(raw || "");
            const t = ctrl.trimLeft(src);
            if (t === "")
                return {
                    mode: ctrl.baseMode,
                    query: ""
                };
            const map = LauncherConfig.searchPrefixes;
            for (var k in map) {
                const expr = String(k || "");
                if (expr === "")
                    continue;
                if (!t.startsWith(expr))
                    continue;
                if (/^[a-zA-Z0-9]+$/.test(expr)) {
                    const next = t.charAt(expr.length);
                    if (next !== "" && next !== undefined && !/\s/.test(next))
                        continue;
                }

                const rest = ctrl.trimLeft(t.slice(expr.length));
                return {
                    mode: ctrl.normalizeMode(String(map[k])),
                    query: rest
                };
            }

            return {
                mode: ctrl.baseMode,
                query: src
            };
        }
        function focusInput() {
            if (ctrl.browseRef && ctrl.browseRef.input)
                ctrl.browseRef.input.forceActiveFocus();
        }
        function goBack() {
            if (directoryBrowser.active) {
                directoryBrowser.goBack();
            } else {
                ctrl.close();
            }
        }
        function launch(modelData) {
            const entry = modelData || ctrl.currentModelData();

            if (directoryBrowser.handleEntry(entry)) {
                return;
            }

            const mode = ctrl.mode || LauncherConfig.modeDrun;
            if (mode === LauncherConfig.modeDrun && entry && entry.path && String(entry.path).length > 0 && !entry._dirMenuAction) {
                if (entry.isDir) {
                    directoryBrowser.openDirectory(entry.path);
                    return;
                } else {
                    directoryBrowser.openFileActions(entry);
                    return;
                }
            }

            if (launchAction && launchAction.launch) {
                launchAction.launch(modelData);
                ctrl.close();
            }
        }
        function normalizeMode(m) {
            const s = (m === undefined || m === null) ? "" : String(m);
            if (LauncherConfig.modeIcons[s] !== undefined)
                return s;
            return LauncherConfig.modeDrun;
        }
        function open(global) {
            directoryBrowser.close();

            ctrl.searchRoot = global ? "/" : Quickshell.env("HOME");
            ctrl.isOpen = true;
            ctrl.baseMode = LauncherConfig.modeDrun;
            ctrl.mode = LauncherConfig.modeDrun;
            ctrl.updateAutoMode();
            ctrl.focusInput();
            ctrl.resetSelection();
        }
        function resetSelection() {
            if (ctrl.browseRef && ctrl.browseRef.list) {
                var len = ctrl.browseRef.resultsCount;
                ctrl.browseRef.list.currentIndex = (len > 0) ? 0 : -1;
            }
        }
        function trimLeft(s) {
            return String(s || "").replace(/^\s+/, "");
        }
        function updateAutoMode() {
            const detected = ctrl.detectModeAndQuery(ctrl.query);
            ctrl.effectiveQuery = detected.query;
            if (ctrl.mode !== detected.mode)
                ctrl.mode = detected.mode;
        }

        onModeChanged: {
            if (directoryBrowser.active)
                directoryBrowser.close();
            if (ctrl.mode === null || ctrl.mode === undefined) {
                return;
            }

            const current = String(ctrl.mode);
            const normalized = ctrl.normalizeMode(current);
            if (normalized !== current)
                ctrl.mode = normalized;
        }
        onQueryChanged: {
            if (directoryBrowser.active)
                directoryBrowser.close();
            ctrl.updateAutoMode();
        }

        ScriptModel {
            id: filtered

            values: {
                if (ctrl.mode === LauncherConfig.modeDrun)
                    return provider.results;
                return [];
            }
        }
        Provider {
            id: provider

            enabled: ctrl.mode === LauncherConfig.modeDrun
            query: ctrl.effectiveQuery
            searchRoot: ctrl.searchRoot
        }
        SubMenu {
            id: directoryBrowser

            onRequestSelectionReset: ctrl.resetSelection()
        }
        LaunchAction {
            id: launchAction

            browseRef: ctrl.browseRef
            launcherRef: ctrl
        }
    }

    component LauncherWindow: PanelWindow {
        id: win

        property alias browseRef: browse
        property bool fileMenuOpen: false
        required property var launcherRef
        property string mode
        property var resultsModel: []
        property var selectedFileData: null

        signal dismissRequested
        signal entryActivated(var modelData)
        signal queryEdited(string text)

        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.layer: WlrLayer.Overlay
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        onVisibleChanged: {
            if (visible) {
                menuRect.opacity = LauncherConfig.menuEntranceOpacityStart;
                menuRect.scale = LauncherConfig.menuEntranceScaleStart;
                entranceAnim.restart();
            }
        }

        anchors {
            bottom: true
            left: true
            right: true
            top: true
        }
        PanelRect {
            id: menuRect

            function getHeight() {
                var entryH = LauncherConfig.entryHeight;
                var len = (browse && browse.resultsCount !== undefined) ? browse.resultsCount : 0;
                var maxE = LauncherConfig.maxVisibleEntries;
                var visible = Math.min(maxE, len);
                var borderPad = (border && border.width) ? border.width : 0;
                var outerAnchorsPad = borderPad;
                var innerMargins = LauncherConfig.innerMargins;
                var innerSpacing = LauncherConfig.innerSpacing;
                var listSpacing = LauncherConfig.listSpacing;
                var entriesSpacing = (visible > 1) ? listSpacing * (visible - 1) : 0;
                var entriesHeight = (visible > 0) ? (visible * entryH + entriesSpacing) : 0;
                var contentHeight = entryH + (visible > 0 ? (innerSpacing + entriesHeight) : 0);
                var totalPadding = (outerAnchorsPad * 2) + (innerMargins * 2);
                return contentHeight + totalPadding;
            }

            anchors.centerIn: parent
            border.width: LauncherConfig.menuBorderWidth
            clip: true
            color: Qt.rgba(ColorConfig.base.r, ColorConfig.base.g, ColorConfig.base.b, LauncherConfig.menuBgAlpha)
            height: getHeight()
            radius: LauncherConfig.menuRadius
            width: LauncherConfig.menuWidth
            z: 1

            Behavior on height {
                NumberAnimation {
                    duration: LauncherConfig.menuAnimMs
                    easing.type: Easing.InOutQuad
                }
            }

            ParallelAnimation {
                id: entranceAnim

                NumberAnimation {
                    duration: LauncherConfig.menuEntranceMs
                    easing.type: Easing.OutCubic
                    property: "opacity"
                    target: menuRect
                    to: LauncherConfig.menuEntranceOpacityEnd
                }
                NumberAnimation {
                    duration: LauncherConfig.menuEntranceMs
                    easing.type: Easing.OutCubic
                    property: "scale"
                    target: menuRect
                    to: LauncherConfig.menuEntranceScaleEnd
                }
            }
            KeyboardNavigation {
                id: keyboard

                active: win.visible && !win.fileMenuOpen
                anchors.fill: parent
                launcherRef: win.launcherRef

                onRequestClose: () => {
                    win.dismissRequested();
                }
                onRequestLaunch: _shift => {
                    if (win.launcherRef && win.launcherRef.launch)
                        win.launcherRef.launch();
                }
                onRequestMove: (delta, _shift) => {
                    win.fileMenuOpen = false;
                    if (browse && browse.list && browse.list.count > 0)
                        browse.list.currentIndex = (browse.list.currentIndex + browse.list.count + delta) % browse.list.count;
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: menuRect.border.width
                    spacing: 0

                    ColumnLayout {
                        id: browse

                        property int entryHeight: LauncherConfig.entryHeight
                        property int innerMargins: LauncherConfig.innerMargins
                        property int innerSpacing: LauncherConfig.innerSpacing
                        property alias input: searchBarInst.input
                        property alias list: searchResults
                        property int maxVisibleEntries: LauncherConfig.maxVisibleEntries
                        property string mode: win.mode
                        readonly property int resultsCount: (browse.resultsModel && browse.resultsModel.length !== undefined) ? browse.resultsModel.length : 0
                        property var resultsModel: win.resultsModel

                        signal entryActivated(var modelData)
                        signal queryEdited(string text)

                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        Layout.margins: innerMargins
                        Layout.preferredWidth: parent.width * LauncherConfig.menuBrowseWidthRatio
                        spacing: innerSpacing

                        onEntryActivated: win.entryActivated(modelData)
                        onQueryEdited: text => win.queryEdited(text)

                        SearchBar {
                            id: searchBarInst

                            Layout.fillWidth: true
                            mode: browse.mode
                            size: browse.entryHeight

                            input.onTextChanged: {
                                browse.queryEdited(input.text);
                                searchResults.currentIndex = (browse.resultsCount > 0) ? 0 : -1;
                            }
                        }
                        Results {
                            id: searchResults

                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            Layout.preferredHeight: {
                                var visible = Math.min(browse.maxVisibleEntries, browse.resultsCount);
                                return visible * browse.entryHeight;
                            }
                            model: browse.resultsModel

                            Component.onCompleted: {
                                currentIndex = (browse.resultsCount > 0) ? 0 : -1;
                            }
                            onEntryActivated: browse.entryActivated(modelData)
                        }
                    }
                }
            }
            MouseArea {
                id: menuArea

                acceptedButtons: Qt.NoButton
                anchors.fill: parent
            }
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            z: -1

            onClicked: {
                if (!menuArea.containsMouse)
                    win.dismissRequested();
            }
        }
    }

    component KeyboardNavigation: Item {
        id: kbnav

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
                kbnav.requestMove(-1, shift);
                break;
            case Qt.Key_Down:
                kbnav.requestMove(1, shift);
                break;
            case Qt.Key_Enter:
            case Qt.Key_Return:
                kbnav.requestLaunch(shift);
                break;
            case Qt.Key_Escape:
                kbnav.requestClose();
                break;
            default:
                handled = false;
            }

            if (handled)
                event.accepted = true;
        }
    }

    component Results: RowLayout {
        id: results

        property alias count: list.count
        property alias currentIndex: list.currentIndex
        property alias currentItem: list.currentItem
        property alias model: list.model
        property alias visibleEntries: list.visibleEntries

        signal entryActivated(var modelData)

        Layout.fillWidth: true
        spacing: LauncherConfig.resultsSpacing

        Column {
            id: bullets

            height: list.height
            spacing: LauncherConfig.bulletsSpacing

            Repeater {
                model: results.visibleEntries

                Item {
                    required property int index
                    property real size: (list && list.contentItem && list.contentItem.children && list.contentItem.children[index]) ? list.contentItem.children[index].height : (parent ? parent.height : 0)

                    height: size
                    width: size

                    IconImage {
                        anchors.centerIn: parent
                        height: LauncherConfig.bulletsIconSize
                        smooth: true
                        source: GlobalConfig.constellation(index + 1)
                        width: LauncherConfig.bulletsIconSize
                    }
                }
            }
        }
        ListView {
            id: list

            property int entryHeight: LauncherConfig.entryHeight
            property int visibleEntries: {
                if (count === 0 || contentHeight === 0)
                    return 0;
                var avg = contentHeight / count;
                if (avg <= 0)
                    return 0;
                var n = Math.ceil(height / avg);
                if (n < 1)
                    n = 1;
                if (n > LauncherConfig.maxVisibleEntries)
                    n = LauncherConfig.maxVisibleEntries;
                if (n > count)
                    n = count;
                return n;
            }

            function snapToEntry() {
                if (count < 1)
                    return;
                var step = entryHeight + spacing;
                if (step <= 0)
                    return;
                var maxY = Math.max(0, contentHeight - height);
                var y = Math.max(0, Math.min(contentY, maxY));
                var targetY = Math.round(y / step) * step;
                targetY = Math.max(0, Math.min(targetY, maxY));
                if (Math.abs(targetY - contentY) < 0.5)
                    return;
                snapAnim.to = targetY;
                snapAnim.start();
            }

            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            highlightMoveDuration: LauncherConfig.highlightMoveMs
            highlightRangeMode: ListView.ApplyRange
            highlightResizeDuration: LauncherConfig.highlightResizeMs
            keyNavigationWraps: true
            preferredHighlightBegin: 0
            preferredHighlightEnd: height
            spacing: LauncherConfig.listSpacing
            z: 0

            delegate: Item {
                id: entry

                required property int index
                property bool isCurrent: ListView.isCurrentItem
                required property var modelData

                height: (ListView.view && ListView.view.entryHeight) ? ListView.view.entryHeight : LauncherConfig.entryHeight
                width: parent ? parent.width : 0
                z: 1

                Rectangle {
                    anchors.fill: parent
                    border.color: hover.containsMouse && !entry.isCurrent ? ColorConfig.accent : "transparent"
                    border.width: LauncherConfig.entryBorderWidth
                    color: ColorConfig.textAlpha03
                    radius: LauncherConfig.entryRadius
                    z: 0
                }
                MouseArea {
                    id: hover

                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: {
                        if (ListView.view)
                            ListView.view.currentIndex = index;
                        results.entryActivated(entry.modelData);
                    }
                }
                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    anchors.fill: parent
                    anchors.leftMargin: LauncherConfig.entryContentMargin
                    anchors.rightMargin: LauncherConfig.entryContentMargin
                    spacing: LauncherConfig.entryContentSpacing

                    Item {
                        property bool useGlyph: !!(entry.modelData && entry.modelData.iconGlyph && String(entry.modelData.iconGlyph).length > 0)

                        Layout.alignment: Qt.AlignVCenter
                        height: LauncherConfig.entryIconSize
                        width: LauncherConfig.entryIconSize

                        IconImage {
                            anchors.fill: parent
                            source: Quickshell.iconPath(entry.modelData?.icon ?? "application-x-executable", "image-missing")
                            visible: !parent.useGlyph
                        }
                        Text {
                            anchors.centerIn: parent
                            color: ColorConfig.text
                            font.family: IconConfig.fontFamily
                            font.pointSize: LauncherConfig.entryIconGlyphPointSize
                            horizontalAlignment: Text.AlignHCenter
                            text: entry.modelData?.iconGlyph ?? ""
                            verticalAlignment: Text.AlignVCenter
                            visible: parent.useGlyph
                        }
                    }
                    Item {
                        id: textBox

                        property bool hasPath: !!(entry.modelData && entry.modelData.path && String(entry.modelData.path).length > 0)

                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true
                        height: parent.height

                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: textBox.hasPath ? undefined : parent.verticalCenter
                            color: ColorConfig.text
                            elide: Text.ElideRight
                            font.family: FontConfig.fontFamily
                            font.pointSize: LauncherConfig.entryTitlePointSize
                            horizontalAlignment: Text.AlignLeft
                            maximumLineCount: 1
                            text: entry.modelData.name
                            y: textBox.hasPath ? LauncherConfig.entryTitleOffsetY : 0
                        }
                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            color: ColorConfig.text
                            elide: Text.ElideMiddle
                            font.family: FontConfig.fontFamily
                            font.pointSize: LauncherConfig.entrySubtitlePointSize
                            horizontalAlignment: Text.AlignLeft
                            maximumLineCount: 1
                            opacity: LauncherConfig.entrySubtitleOpacity
                            text: {
                                var p = entry.modelData.path || "";
                                var home = Quickshell.env("HOME") || "";
                                return home && (p === home || p.startsWith(home + "/")) ? "~" + p.slice(home.length) : p;
                            }
                            visible: textBox.hasPath
                            y: LauncherConfig.entrySubtitleOffsetY
                        }
                    }
                }
            }
            highlight: Rectangle {
                id: passiveHighlight

                border.color: ColorConfig.accentAlt
                border.width: LauncherConfig.highlightBorderWidth
                color: "transparent"
                opacity: LauncherConfig.highlightOpacity
                radius: LauncherConfig.highlightRadius
                z: -1

                Behavior on height {
                    NumberAnimation {
                        duration: list.highlightResizeDuration
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on y {
                    NumberAnimation {
                        duration: list.highlightMoveDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }

            onDraggingChanged: if (!dragging)
                snapToEntry()
            onFlickEnded: snapToEntry()
            onMovementEnded: snapToEntry()
            onMovementStarted: snapAnim.stop()

            NumberAnimation {
                id: snapAnim

                duration: LauncherConfig.snapAnimMs
                easing.type: Easing.OutCubic
                property: "contentY"
                target: list
            }
        }
    }

    component SearchBar: RowLayout {
        id: searchBar

        property alias input: input
        property string mode
        property int size: LauncherConfig.entryHeight

        spacing: LauncherConfig.searchbarSpacing

        Rectangle {
            Layout.preferredHeight: searchBar.size
            Layout.preferredWidth: searchBar.size
            border.color: ColorConfig.accent
            border.width: LauncherConfig.searchbarBorderWidth
            color: "transparent"
            radius: LauncherConfig.searchbarRadius

            Text {
                anchors.centerIn: parent
                color: ColorConfig.text
                font.family: IconConfig.fontFamily
                font.pixelSize: LauncherConfig.searchbarFontPx
                text: LauncherConfig.modeIcons[searchBar.mode] || ""
            }
        }
        TextField {
            id: input

            Layout.fillWidth: true
            Layout.preferredHeight: searchBar.size
            color: ColorConfig.text
            focus: true
            font.family: FontConfig.fontFamily
            font.pixelSize: LauncherConfig.searchbarFontPx
            leftPadding: LauncherConfig.searchbarPadding
            rightPadding: LauncherConfig.searchbarPadding
            verticalAlignment: Text.AlignVCenter
            z: 2

            background: Rectangle {
                border.color: ColorConfig.accent
                border.width: LauncherConfig.searchbarBorderWidth
                color: "transparent"
                radius: LauncherConfig.searchbarRadius
            }
        }
    }

    component AppsProvider: Item {
        id: appsP

        property string query: ""
        property var results: []

        function compute() {
            const q = (appsP.query || "").trim().toLowerCase();
            if (q === "") {
                appsP.results = [];
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

            appsP.results = res;
        }

        Component.onCompleted: compute()
        onQueryChanged: compute()
    }

    component FilesProvider: Item {
        id: filesP

        property int debounceInterval: 120
        property bool dirsDone: false
        property var dirsResults: []
        property bool filesDone: false
        property var filesResults: []
        property int maxResults: 50
        property string pendingQuery: ""
        property string query: ""
        property var results: []
        property string runningPattern: ""
        property string runningQuery: ""
        property string searchRoot: "/"

        function basename(p) {
            if (!p)
                return "";
            const s = filesP.normalizePath(p);
            const parts = s.split("/");
            return parts.length ? parts[parts.length - 1] : s;
        }
        function clearAll() {
            filesP.results = [];
            filesP.pendingQuery = "";
            filesP.runningQuery = "";
            filesP.runningPattern = "";
            filesP.dirsDone = false;
            filesP.filesDone = false;
            filesP.dirsResults = [];
            filesP.filesResults = [];
            searchDirs.running = false;
            searchFiles.running = false;
        }
        function makeEntry(path, isDir) {
            const display = filesP.basename(path);
            const entry = {
                name: display,
                isDir: !!isDir,
                path: path,
                _score: filesP.orderedMatchScore(display, filesP.runningQuery),
                execute: function () {
                    Quickshell.execDetached(["xdg-open", path]);
                }
            };
            if (isDir)
                entry.iconGlyph = IconConfig.folder;
            else
                entry.icon = "text-x-generic";
            return entry;
        }
        function maybeUpdateResults() {
            if (!filesP.dirsDone || !filesP.filesDone)
                return;

            let combined = filesP.dirsResults.concat(filesP.filesResults);
            combined.sort(function (a, b) {
                const aIsDir = !!(a && a.isDir);
                const bIsDir = !!(b && b.isDir);
                if (aIsDir && !bIsDir)
                    return -1;
                if (bIsDir && !aIsDir)
                    return 1;

                const as = (a && a._score !== undefined) ? a._score : 0;
                const bs = (b && b._score !== undefined) ? b._score : 0;
                if (as !== bs)
                    return bs - as;

                const an = ((a && a.name) ? a.name : "").toLowerCase();
                const bn = ((b && b.name) ? b.name : "").toLowerCase();
                if (an < bn)
                    return -1;
                if (an > bn)
                    return 1;
                return 0;
            });

            filesP.results = combined.slice(0, filesP.maxResults);
        }
        function normalizePath(p) {
            if (!p)
                return "";
            let s = String(p);
            while (s.length > 1 && s.endsWith("/"))
                s = s.slice(0, -1);
            return s;
        }
        function orderedMatchScore(name, q) {
            const n = (name || "").toLowerCase();
            const raw = (q || "").trim().toLowerCase();
            if (n === "" || raw === "")
                return -1;

            const parts = filesP.splitQueryParts(raw);
            if (parts.length === 0)
                return -1;

            let score = 0;
            let cursor = 0;
            for (let i = 0; i < parts.length; i += 1) {
                const part = parts[i];
                const idx = n.indexOf(part, cursor);
                if (idx < 0)
                    return -1;
                if (i === 0) {
                    if (idx === 0)
                        score += 1000;
                    else
                        score += 500;
                } else {
                    score += 200;
                }
                score -= Math.min(idx, 200);
                cursor = idx + part.length;
            }
            score -= Math.min(n.length, 200) / 10;
            return score;
        }
        function parseLines(raw) {
            return (raw || "").split("\n").map(l => l.trim()).filter(l => l.length > 0);
        }
        function requestSearch(q) {
            if (!filesP.enabled) {
                filesP.clearAll();
                return;
            }
            const trimmed = (q || "").trim();
            if (trimmed === "") {
                filesP.clearAll();
                return;
            }
            if (filesP.debounceInterval <= 0) {
                filesP.startSearch(trimmed);
                return;
            }
            filesP.pendingQuery = trimmed;
            debounce.restart();
        }
        function splitQueryParts(q) {
            const s = (q || "").trim().toLowerCase();
            if (s === "")
                return [];
            if (!s.includes("*"))
                return [s];
            return s.split("*").map(p => p.trim()).filter(p => p.length > 0);
        }
        function startSearch(q) {
            filesP.runningQuery = (q || "").trim();
            filesP.runningPattern = filesP.toGlobPattern(filesP.runningQuery);

            if (filesP.runningQuery === "") {
                filesP.clearAll();
                return;
            }

            searchDirs.running = false;
            searchFiles.running = false;
            filesP.dirsDone = false;
            filesP.filesDone = false;
            filesP.dirsResults = [];
            filesP.filesResults = [];
            searchDirs.running = true;
            searchFiles.running = true;
        }
        function toGlobPattern(q) {
            const s = (q || "").trim();
            if (s === "")
                return "";
            if (s.startsWith("**/") || s.startsWith("/"))
                return s;
            if (s.includes("/"))
                return "**/" + s;
            return "**/*" + s + "*";
        }

        enabled: false

        onEnabledChanged: filesP.requestSearch(query)
        onQueryChanged: filesP.requestSearch(query)

        Timer {
            id: debounce

            interval: filesP.debounceInterval
            repeat: false

            onTriggered: filesP.startSearch(filesP.pendingQuery)
        }
        Search {
            id: searchDirs

            isDir: true
            filesOwner: filesP
            type: "d"

            onSearchFinished: entries => {
                filesP.dirsResults = entries;
                filesP.dirsDone = true;
                filesP.maybeUpdateResults();
            }
        }
        Search {
            id: searchFiles

            isDir: false
            filesOwner: filesP
            type: "f"

            onSearchFinished: entries => {
                filesP.filesResults = entries;
                filesP.filesDone = true;
                filesP.maybeUpdateResults();
            }
        }
    }

    component Search: Process {
        id: search

        property bool isDir
        required property Item filesOwner
        property string type

        signal searchFinished(var entries)

        command: ["fd", "--glob", "--ignore-case", "--full-path", "--type", search.type, "--hidden", "--no-ignore", "--absolute-path", "--color", "never", "--max-results", String(filesOwner.maxResults), "--", filesOwner.runningPattern, filesOwner.searchRoot]

        stdout: StdioCollector {
            id: collector

            onStreamFinished: {
                const lines = filesOwner.parseLines(collector.text);
                search.searchFinished(lines.map(path => filesOwner.makeEntry(path, search.isDir)));
            }
        }
    }

    component LaunchAction: Item {
        id: launchA

        property var browseRef
        property var launcherRef

        function currentModelData() {
            var current = (browseRef && browseRef.list) ? browseRef.list.currentItem : null;
            if (current && current.modelData)
                return current.modelData;
            return null;
        }
        function launch(modelData) {
            var mode = launcherRef.mode || LauncherConfig.modeDrun;
            var execDone = false;
            var launchedEntry = null;

            if (mode == LauncherConfig.modeDrun) {
                if (modelData) {
                    launchedEntry = modelData;
                    execDone = launchDesktopOrFileModel(modelData);
                }
                if (!execDone) {
                    launchedEntry = launchA.currentModelData();
                    execDone = launchDesktopOrFile();
                }
                if (!execDone && !(launcherRef && launcherRef.subMenuOpen) && (browseRef && browseRef.list && browseRef.list.count === 0))
                    execDone = launchDefaultWeb();

                if (execDone && launchedEntry)
                    VisitStore.recordVisit(launchedEntry);
            } else if (mode == LauncherConfig.modeRun)
                execDone = launchRun();
            else if (mode == LauncherConfig.modeGoogle)
                execDone = launchGoogle();
            else if (mode == LauncherConfig.modeDuckDuckGo)
                execDone = launchDuckDuckGo();
            else if (mode == LauncherConfig.modeYouTube)
                execDone = launchYouTube();
            else if (mode == LauncherConfig.modeUrl)
                execDone = launchUrl();
        }
        function launchDefaultWeb() {
            var txt = (launcherRef && launcherRef.effectiveQuery !== undefined) ? String(launcherRef.effectiveQuery) : (browseRef && browseRef.input ? browseRef.input.text : "");
            var url = resolveWebTarget(txt, "https://www.google.com/search?q=");
            if (url === "")
                return false;
            Quickshell.execDetached(["xdg-open", url]);
            return true;
        }
        function launchDesktopOrFile() {
            var current = browseRef.list.currentItem;
            if (!(current && current.modelData))
                return false;
            try {
                if (typeof current.modelData.execute === 'function')
                    current.modelData.execute();
                return true;
            } catch (e) {
                console.log("Error executing current.modelData:", e);
                return false;
            }
        }
        function launchDesktopOrFileModel(modelData) {
            if (!modelData)
                return false;
            try {
                if (typeof modelData.execute === 'function')
                    modelData.execute();
                return true;
            } catch (e) {
                console.log("Error executing modelData:", e);
                return false;
            }
        }
        function launchDuckDuckGo() {
            var txt = (launcherRef && launcherRef.effectiveQuery !== undefined) ? String(launcherRef.effectiveQuery) : (browseRef && browseRef.input ? browseRef.input.text : "");
            var url = makeSearchUrl(txt, "https://duckduckgo.com/?q=");
            if (url === "")
                return false;
            Quickshell.execDetached(["xdg-open", url]);
            return true;
        }
        function launchGoogle() {
            var txt = (launcherRef && launcherRef.effectiveQuery !== undefined) ? String(launcherRef.effectiveQuery) : (browseRef && browseRef.input ? browseRef.input.text : "");
            var url = makeSearchUrl(txt, "https://www.google.com/search?q=");
            if (url === "")
                return false;
            Quickshell.execDetached(["xdg-open", url]);
            return true;
        }
        function launchRun() {
            var txt = (launcherRef && launcherRef.effectiveQuery !== undefined) ? String(launcherRef.effectiveQuery) : (browseRef && browseRef.input ? browseRef.input.text : "");
            Quickshell.execDetached(["zsh", "-lic", txt]);
            return true;
        }
        function launchUrl() {
            var txt = (launcherRef && launcherRef.effectiveQuery !== undefined) ? String(launcherRef.effectiveQuery) : (browseRef && browseRef.input ? browseRef.input.text : "");
            var url = normalizeUrl(txt);
            if (url === "")
                return false;
            Quickshell.execDetached(["xdg-open", url]);
            return true;
        }
        function launchYouTube() {
            var txt = (launcherRef && launcherRef.effectiveQuery !== undefined) ? String(launcherRef.effectiveQuery) : (browseRef && browseRef.input ? browseRef.input.text : "");
            var url = makeSearchUrl(txt, "https://www.youtube.com/results?search_query=");
            if (url === "")
                return false;
            Quickshell.execDetached(["xdg-open", url]);
            return true;
        }
        function makeSearchUrl(txt, searchBaseUrl) {
            var t = (txt || "").trim();
            if (t === "")
                return "";
            return String(searchBaseUrl || "") + encodeURIComponent(t);
        }
        function normalizeUrl(txt) {
            var t = (txt || "").trim();
            if (t === "")
                return "";
            if (/^[a-zA-Z][a-zA-Z0-9+.-]*:\/\//.test(t))
                return t;
            if (t.startsWith("//"))
                return "https:" + t;
            if (/\s/.test(t))
                return "";
            if (/^localhost([:/].*)?$/.test(t))
                return "http://" + t;
            if (/^\d{1,3}(?:\.\d{1,3}){3}([:/].*)?$/.test(t))
                return "http://" + t;
            if (/^[^\s@]+\.[^\s@]+$/.test(t))
                return "http://" + t;
            if (/^[^\s/]+:\d+(?:\/.*)?$/.test(t))
                return "http://" + t;
            return "";
        }
        function resolveWebTarget(txt, searchBaseUrl) {
            var url = normalizeUrl(txt);
            if (url !== "")
                return url;
            return makeSearchUrl(txt, searchBaseUrl);
        }
    }

    component Provider: Item {
        id: providerP

        property bool filesEnabled: true
        property int maxResults: 50
        property string pendingQuery: ""
        property string query: ""
        property var results: []
        property string runningQuery: ""
        property string searchRoot: "/"

        function computeAppScore(entry, qLower) {
            const name = (entry && entry.name) ? String(entry.name).toLowerCase() : "";
            if (name === "" || qLower === "")
                return -1;

            const idx = name.indexOf(qLower);
            if (idx < 0)
                return -1;

            let score = (idx === 0) ? 1000 : 500;
            score -= Math.min(idx, 200);
            score -= Math.min(name.length, 200) / 10;
            return score;
        }
        function recompute() {
            const q = (providerP.runningQuery || "").trim();
            const qLower = q.toLowerCase();

            if (!providerP.enabled || qLower === "") {
                providerP.results = [];
                return;
            }

            const decorated = [];

            const appRes = apps.results || [];
            for (let i = 0; i < appRes.length; i += 1) {
                const it = appRes[i];
                const visits = VisitStore.getCount(it);
                decorated.push({
                    item: it,
                    kind: "app",
                    isDir: false,
                    score: providerP.computeAppScore(it, qLower),
                    visits: visits,
                    nameLower: (it && it.name) ? String(it.name).toLowerCase() : ""
                });
            }

            const fileRes = files.results || [];
            for (let j = 0; j < fileRes.length; j += 1) {
                const it2 = fileRes[j];
                const score2 = (it2 && it2._score !== undefined) ? it2._score : providerP.computeAppScore(it2, qLower);
                const visits2 = VisitStore.getCount(it2);
                decorated.push({
                    item: it2,
                    kind: "file",
                    isDir: !!(it2 && it2.isDir),
                    score: score2,
                    visits: visits2,
                    nameLower: (it2 && it2.name) ? String(it2.name).toLowerCase() : ""
                });
            }

            decorated.sort(function (a, b) {
                const aRank = (a.kind === "app") ? 0 : (a.isDir ? 1 : 2);
                const bRank = (b.kind === "app") ? 0 : (b.isDir ? 1 : 2);
                if (aRank !== bRank)
                    return aRank - bRank;

                const av = (a.visits !== undefined) ? a.visits : 0;
                const bv = (b.visits !== undefined) ? b.visits : 0;
                if (av !== bv)
                    return bv - av;

                const as = (a.score !== undefined) ? a.score : 0;
                const bs = (b.score !== undefined) ? b.score : 0;
                if (as !== bs)
                    return bs - as;

                if (a.nameLower < b.nameLower)
                    return -1;
                if (a.nameLower > b.nameLower)
                    return 1;
                return 0;
            });

            providerP.results = decorated.slice(0, providerP.maxResults).map(d => d.item);
        }
        function scheduleQueryUpdate() {
            if (!providerP.enabled) {
                providerP.pendingQuery = "";
                providerP.runningQuery = "";
                providerP.results = [];
                return;
            }

            const q = (providerP.query || "");
            if (q.trim() === "") {
                providerP.pendingQuery = "";
                providerP.runningQuery = "";
                providerP.results = [];
                return;
            }

            providerP.pendingQuery = q;
            queryDebounce.restart();
        }

        onEnabledChanged: scheduleQueryUpdate()
        onFilesEnabledChanged: recompute()
        onMaxResultsChanged: recompute()
        onQueryChanged: scheduleQueryUpdate()

        Connections {
            function onChanged() {
                providerP.recompute();
            }

            target: VisitStore
        }
        Timer {
            id: queryDebounce

            interval: 120
            repeat: false

            onTriggered: {
                if (!providerP.enabled) {
                    providerP.runningQuery = "";
                    providerP.results = [];
                    return;
                }

                const q = (providerP.pendingQuery || "").trim();
                providerP.runningQuery = q;
                providerP.recompute();
            }
        }
        AppsProvider {
            id: apps

            query: providerP.runningQuery

            onResultsChanged: providerP.recompute()
        }
        FilesProvider {
            id: files

            debounceInterval: 0
            enabled: providerP.enabled && providerP.filesEnabled
            maxResults: providerP.maxResults
            query: providerP.runningQuery
            searchRoot: providerP.searchRoot

            onResultsChanged: providerP.recompute()
        }
    }

    component SubMenu: Item {
        id: subMenu

        property bool active: false
        property var baseItems: []
        property bool cameFromBrowse: false
        property string currentPath: ""
        property var dirItems: []
        readonly property string editor: LauncherConfig.editor
        property var fileItems: []
        property int maxResults: 50
        property string menuState: "search"
        property var results: []

        signal requestSelectionReset

        function basename(p) {
            var s = subMenu.normalizePath(p);
            var parts = s.split("/");
            return parts.length ? parts[parts.length - 1] : s;
        }
        function close() {
            subMenu.active = false;
            subMenu.menuState = "search";
            subMenu.cameFromBrowse = false;
            subMenu.currentPath = "";
            subMenu.results = [];
            subMenu.baseItems = [];
            subMenu.dirItems = [];
            subMenu.fileItems = [];
            dirMenuDirs.running = false;
            dirMenuFiles.running = false;
        }
        function goBack() {
            if (!subMenu.active)
                return false;

            if (subMenu.menuState === "dir_actions") {
                subMenu.openDirectory(subMenu.currentPath);
                return true;
            } else if (subMenu.menuState === "file_actions") {
                if (subMenu.cameFromBrowse) {
                    var p = subMenu.currentPath;
                    var dirPath = p;
                    var lastSlash = p.lastIndexOf("/");
                    if (lastSlash > 0) {
                        dirPath = p.substring(0, lastSlash);
                    } else if (lastSlash === 0) {
                        dirPath = "/";
                    }
                    subMenu.openDirectory(dirPath);
                } else {
                    subMenu.close();
                }
                return true;
            } else if (subMenu.menuState === "browse") {
                subMenu.close();
                return true;
            }
            return false;
        }
        function handleEntry(entry) {
            if (!entry || !entry._dirMenuAction)
                return false;

            if (entry._dirMenuAction === "back") {
                subMenu.close();
                return true;
            }
            if (entry._dirMenuAction === "open_options" || entry._dirMenuAction === "open_contain_dir") {
                subMenu.openDirectoryActions(entry.path);
                return true;
            }
            if (entry._dirMenuAction === "prev_dir") {
                const p = subMenu.currentPath;
                if (p === "/")
                    return true;
                const i = p.lastIndexOf("/");
                if (i < 0)
                    return true;
                const parent = (i <= 0) ? "/" : p.slice(0, i);
                subMenu.openDirectory(parent);
                return true;
            }
            return false;
        }
        function makePathEntry(path, isDir) {
            const p = String(path || "");
            const display = subMenu.basename(p);
            const entry = {
                name: display,
                path: p,
                isDir: !!isDir,
                execute: function () {
                    Quickshell.execDetached(["xdg-open", p]);
                }
            };

            if (isDir)
                entry.iconGlyph = IconConfig.folder;
            else
                entry.icon = "text-x-generic";

            return entry;
        }
        function normalizePath(p) {
            var s = (p === undefined || p === null) ? "" : String(p);
            while (s.length > 1 && s.endsWith("/"))
                s = s.slice(0, -1);
            return s;
        }
        function openDirectory(path) {
            const p = subMenu.normalizePath(path);
            if (p === "")
                return;

            const baseActions = [
                {
                    name: "Open Directory",
                    path: p,
                    isDir: true,
                    iconGlyph: IconConfig.arrowRight,
                    _dirMenuAction: "open_options"
                },
                {
                    name: "Previous Directory",
                    path: p,
                    isDir: true,
                    iconGlyph: IconConfig.arrowLeft,
                    _dirMenuAction: "prev_dir"
                }
            ];
            subMenu.setup("browse", p, baseActions, true);
        }
        function openDirectoryActions(path) {
            const p = subMenu.normalizePath(path);
            if (p === "")
                return;

            const baseActions = [
                {
                    name: "Open Directory in File Manager",
                    path: p,
                    isDir: true,
                    iconGlyph: IconConfig.arrowRight,
                    _dirMenuAction: "dir_open_fm",
                    execute: function () {
                        Quickshell.execDetached(["xdg-open", p]);
                    }
                },
                {
                    name: "Open Directory in " + subMenu.editor,
                    path: p,
                    isDir: true,
                    iconGlyph: IconConfig.code,
                    _dirMenuAction: "dir_open_vsc",
                    execute: function () {
                        Quickshell.execDetached([subMenu.editor, p]);
                    }
                },
                {
                    name: "Open Directory in Terminal",
                    path: p,
                    isDir: true,
                    iconGlyph: IconConfig.terminal,
                    _dirMenuAction: "dir_open_tm",
                    execute: function () {
                        Quickshell.execDetached(["kitty", p]);
                    }
                }
            ];
            subMenu.setup("dir_actions", p, baseActions, false);
        }
        function openFileActions(entry) {
            const p = subMenu.normalizePath(entry.path);
            if (p === "")
                return;

            var dirPath = p;
            var lastSlash = p.lastIndexOf("/");
            if (lastSlash > 0) {
                dirPath = p.substring(0, lastSlash);
            } else if (lastSlash === 0) {
                dirPath = "/";
            }

            const baseActions = [
                {
                    name: "Open File",
                    path: p,
                    isDir: false,
                    iconGlyph: IconConfig.arrowRight,
                    _dirMenuAction: "file_open",
                    execute: function () {
                        Quickshell.execDetached(["xdg-open", p]);
                    }
                },
                {
                    name: "Open Containing Directory",
                    path: dirPath,
                    isDir: true,
                    iconGlyph: IconConfig.folderOpen,
                    _dirMenuAction: "open_contain_dir",
                    execute: function () {
                        Quickshell.execDetached(["xdg-open", dirPath]);
                    }
                }
            ];
            subMenu.cameFromBrowse = (subMenu.active && subMenu.menuState === "browse");
            subMenu.setup("file_actions", p, baseActions, false);
        }
        function parseLines(raw) {
            return (raw || "").split("\n").map(l => l.trim()).filter(l => l.length > 0);
        }
        function rebuildMenu() {
            subMenu.results = (subMenu.baseItems || []).concat(subMenu.dirItems || [], subMenu.fileItems || []);
        }
        function setup(newState, path, baseActions, loadContents) {
            dirMenuDirs.running = false;
            dirMenuFiles.running = false;
            subMenu.dirItems = [];
            subMenu.fileItems = [];

            subMenu.active = true;
            subMenu.menuState = newState;
            subMenu.currentPath = path;
            subMenu.baseItems = baseActions;
            subMenu.rebuildMenu();
            subMenu.requestSelectionReset();

            if (loadContents) {
                dirMenuDirs.running = true;
                dirMenuFiles.running = true;
            }
        }

        FdListProcess {
            id: dirMenuDirs

            isDir: true
            menu: subMenu
            type: "d"

            onListFinished: entries => {
                subMenu.dirItems = entries;
                subMenu.rebuildMenu();
            }
        }
        FdListProcess {
            id: dirMenuFiles

            isDir: false
            menu: subMenu
            type: "f"

            onListFinished: entries => {
                subMenu.fileItems = entries;
                subMenu.rebuildMenu();
            }
        }
    }

    component FdListProcess: Process {
        id: control

        property bool isDir
        required property Item menu
        property string type

        signal listFinished(var entries)

        command: ["fd", "--glob", "--type", control.type, "--hidden", "--no-ignore", "--absolute-path", "--color", "never", "--max-depth", "1", "--max-results", String(menu.maxResults), "--exclude", ".git", "--", "*", menu.currentPath]

        stdout: StdioCollector {
            id: fdCollector

            onStreamFinished: {
                const lines = menu.parseLines(fdCollector.text);
                control.listFinished(lines.map(p => menu.makePathEntry(p, control.isDir)));
            }
        }
    }
}
