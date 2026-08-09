pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.service
import qs.settings
import qs.settings.layout.tabs.wallpapertab
import qs.wallpaper

Item {
    id: root

    property int selectedColumn: 0
    readonly property var selectedFillModeMap: {
        var arr = WallpaperService.staticFillModes[root.selectedScreen] ?? [];
        var m = {};
        m[root.selectedScreen] = arr[root.selectedColumn] ?? "crop";
        return m;
    }
    property string selectedScreen: {
        var focusedName = HyprlandService.focusedMonitor?.name ?? "";
        if (focusedName && root.sortedScreens.some(s => s.name === focusedName))
            return focusedName;
        return root.sortedScreens.length > 0 ? root.sortedScreens[0].name : "";
    }
    readonly property var selectedWallpaperMap: {
        var arr = WallpaperService.staticWallpapers[root.selectedScreen] ?? [];
        var m = {};
        m[root.selectedScreen] = arr[root.selectedColumn] ?? "";
        return m;
    }
    readonly property var sortedScreens: {
        var screens = [];
        for (var i = 0; i < Quickshell.screens.length; i++)
            screens.push(Quickshell.screens[i]);
        screens.sort(function (a, b) {
            return a.name < b.name ? -1 : a.name > b.name ? 1 : 0;
        });
        return screens;
    }

    ColumnLayout {
        id: colLayout

        anchors.fill: parent
        spacing: WallpaperConfig.columnSpacing

        RegionRow {
            Layout.fillWidth: true
            Layout.preferredHeight: WallpaperConfig.controlRowHeight
            columnsMap: WallpaperService.staticColumns
            screens: root.sortedScreens
            selectedColumn: root.selectedColumn
            selectedScreen: root.selectedScreen

            onRegionSelected: (screenName, columnIndex) => {
                root.selectedScreen = screenName;
                root.selectedColumn = columnIndex;
            }
        }
        DirBar {
            id: dirBar

            Layout.fillWidth: true
            Layout.preferredHeight: WallpaperConfig.dirBarHeight
            currentDir: WallpaperService.staticDir
            scanning: WallpaperService.staticScanning

            onDirChangeRequested: path => WallpaperService.setStaticDir(path)
            onEscapePressed: {}
        }
        ControlRow {
            id: controlRow

            Layout.fillWidth: true
            Layout.preferredHeight: WallpaperConfig.controlRowHeight
            columnCount: WallpaperService.staticColumns[root.selectedScreen] ?? 1
            fillModes: root.selectedFillModeMap
            selectedScreen: root.selectedScreen
            wallpapers: root.selectedWallpaperMap

            onColumnCountChangeRequested: n => {
                WallpaperService.setStaticColumns(root.selectedScreen, n);
                if (root.selectedColumn >= n)
                    root.selectedColumn = n - 1;
            }
            onFillModeChanged: mode => WallpaperService.setStaticFillMode(root.selectedScreen, root.selectedColumn, mode)
            onWallpaperRemoved: WallpaperService.removeStaticWallpaper(root.selectedScreen, root.selectedColumn)
        }
        ImageGrid {
            Layout.fillHeight: true
            Layout.fillWidth: true
            imageFiles: WallpaperService.staticFiles
            selectedScreen: root.selectedScreen
            wallpapers: root.selectedWallpaperMap

            onWallpaperSelected: path => WallpaperService.setStaticWallpaper(root.selectedScreen, root.selectedColumn, path)
        }
    }
}
