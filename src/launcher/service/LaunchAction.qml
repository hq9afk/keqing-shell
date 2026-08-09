pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.launcher
import qs.launcher.service

Item {
    id: root

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
                launchedEntry = root.currentModelData();
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
