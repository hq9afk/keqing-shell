pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.service
import qs.modules.settings
import qs.modules.settings.layout.tabs.wallpapertab
import qs.modules.wallpaper

Item {
    id: root

    property int selectedColumn: 0
    property string selectedScreen: {
        var focusedName = HyprlandService.focusedMonitor?.name ?? "";
        if (focusedName && root.sortedScreens.some(s => s.name === focusedName))
            return focusedName;
        return root.sortedScreens.length > 0 ? root.sortedScreens[0].name : "";
    }
    readonly property var selectedVideoMap: {
        var arr = WallpaperService.animatedWallpapers[root.selectedScreen] ?? [];
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
            columnsMap: WallpaperService.animatedColumns
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
            currentDir: WallpaperService.animatedDir
            scanning: WallpaperService.animatedScanning

            onDirChangeRequested: path => WallpaperService.setAnimatedDir(path)
            onEscapePressed: {}
        }
        ControlRow {
            id: controlRow

            Layout.fillWidth: true
            Layout.preferredHeight: WallpaperConfig.controlRowHeight
            columnCount: WallpaperService.animatedColumns[root.selectedScreen] ?? 1
            fillModeSupported: false
            selectedScreen: root.selectedScreen
            wallpapers: root.selectedVideoMap

            onColumnCountChangeRequested: n => {
                WallpaperService.setAnimatedColumns(root.selectedScreen, n);
                if (root.selectedColumn >= n)
                    root.selectedColumn = n - 1;
            }
            onWallpaperRemoved: WallpaperService.removeAnimatedWallpaper(root.selectedScreen, root.selectedColumn)
        }
        ImageGrid {
            Layout.fillHeight: true
            Layout.fillWidth: true
            imageFiles: WallpaperService.animatedFiles
            previewSources: WallpaperService.animatedThumbnails
            selectedScreen: root.selectedScreen
            wallpapers: root.selectedVideoMap

            onWallpaperSelected: path => WallpaperService.setAnimatedWallpaper(root.selectedScreen, root.selectedColumn, path)
        }
    }
}
