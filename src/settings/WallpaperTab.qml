pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.elements
import qs.service
import qs.settings
import qs.config

Item {
    component DirBar: Rectangle {
        id: dirBar

        property string currentDir: ""
        property bool scanning: false

        signal dirChangeRequested(string path)
        signal escapePressed

        function resetDir() {
            dirInput.text = dirBar.currentDir;
        }

        border.color: ColorConfig.accent
        border.width: dirInput.activeFocus ? GlobalConfig.borderWidthThin : 0
        color: ColorConfig.fieldBg
        height: WallpaperConfig.dirBarHeight
        radius: GlobalConfig.radiusSm + SettingsConfig.thumbnailRadiusBoost

        Component.onCompleted: dirInput.text = dirBar.currentDir
        onCurrentDirChanged: {
            if (!dirInput.activeFocus)
                dirInput.text = dirBar.currentDir;
        }

        Text {
            id: dirLabel

            anchors.left: parent.left
            anchors.leftMargin: WallpaperConfig.dirLabelLeftMargin
            anchors.verticalCenter: parent.verticalCenter
            color: ColorConfig.accent
            font.bold: true
            font.family: FontConfig.fontFamily
            font.pixelSize: FontConfig.fontSettingsBody
            text: "Dir"
        }
        TextInput {
            id: dirInput

            anchors.left: dirLabel.right
            anchors.leftMargin: WallpaperConfig.dirInputLeftMargin
            anchors.right: rescanBtn.left
            anchors.rightMargin: WallpaperConfig.dirEdgeMargin
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            color: ColorConfig.text
            font.family: FontConfig.fontFamily
            font.pixelSize: FontConfig.fontSettingsBody
            selectByMouse: true

            Keys.onEscapePressed: dirBar.escapePressed()
            Keys.onReturnPressed: dirBar.dirChangeRequested(dirInput.text.trim())
        }
        Rectangle {
            id: rescanBtn

            anchors.right: parent.right
            anchors.rightMargin: WallpaperConfig.dirEdgeMargin
            anchors.verticalCenter: parent.verticalCenter
            color: rescanArea.containsMouse ? ColorConfig.accent : Qt.rgba(1, 1, 1, 0.08)
            height: WallpaperConfig.dirBtnHeight
            radius: GlobalConfig.radiusSm
            width: WallpaperConfig.dirBtnWidth

            Behavior on color {
                ColorAnimation {
                    duration: SettingsConfig.quickColorAnimMs
                }
            }

            Text {
                anchors.centerIn: parent
                color: ColorConfig.text
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontSettingsBody
                text: dirBar.scanning ? "…" : "Rescan"
            }
            MouseArea {
                id: rescanArea

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: !dirBar.scanning
                hoverEnabled: true

                onClicked: dirBar.dirChangeRequested(dirInput.text.trim())
            }
        }
    }

    component RegionRow: Item {
        id: root

        property var columnsMap: ({})
        readonly property var regions: {
            var out = [];
            for (var i = 0; i < root.screens.length; i++) {
                var screen = root.screens[i];
                var n = root.columnsMap[screen.name] ?? 1;
                for (var c = 0; c < n; c++)
                    out.push({
                        screenName: screen.name,
                        columnIndex: c,
                        label: n > 1 ? screen.name + "-" + (c + 1) : screen.name
                    });
            }
            return out;
        }
        property var screens: []
        property int selectedColumn: 0
        property string selectedScreen: ""

        signal regionSelected(string screenName, int columnIndex)

        implicitHeight: WallpaperConfig.controlRowHeight

        Row {
            id: regionRow

            anchors.fill: parent
            spacing: WallpaperConfig.dropdownBtnSpacing

            Repeater {
                model: root.regions

                delegate: Rectangle {
                    id: regionBtn

                    required property var modelData

                    border.color: root.selectedScreen === regionBtn.modelData.screenName && root.selectedColumn === regionBtn.modelData.columnIndex ? ColorConfig.accentAlt : "transparent"
                    border.width: SettingsConfig.selectorBorderWidth
                    color: ColorConfig.lavenderAlpha20
                    height: WallpaperConfig.controlRowHeight
                    radius: GlobalConfig.radiusSm
                    width: (regionRow.width - (root.regions.length - 1) * regionRow.spacing) / Math.max(1, root.regions.length)

                    Behavior on border.color {
                        ColorAnimation {
                            duration: SettingsConfig.quickColorAnimMs
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        color: ColorConfig.text
                        font.family: FontConfig.fontFamily
                        font.pixelSize: FontConfig.fontSettingsBody
                        text: regionBtn.modelData.label
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: root.regionSelected(regionBtn.modelData.screenName, regionBtn.modelData.columnIndex)
                    }
                }
            }
        }
    }

    component ControlRow: Item {
        id: controlRow

        property int columnCount: 1
        property bool fillModeSupported: true
        property var fillModes: ({})
        property string selectedScreen: ""
        property var wallpapers: ({})

        signal columnCountChangeRequested(int n)
        signal fillModeChanged(string mode)
        signal wallpaperRemoved

        height: WallpaperConfig.controlRowHeight

        // inlined CountStepper (single use)
        Item {
            id: stepper

            property int minValue: 1

            function clamp(n) {
                return Math.max(stepper.minValue, n);
            }

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            implicitHeight: WallpaperConfig.controlRowHeight - SettingsConfig.groupContentSpacingSm
            implicitWidth: decBtn.width + numBox.width + incBtn.width + WallpaperConfig.dropdownBtnSpacing * 2

            Row {
                anchors.fill: parent
                spacing: WallpaperConfig.dropdownBtnSpacing

                Rectangle {
                    id: decBtn

                    color: ColorConfig.lavenderAlpha20
                    height: WallpaperConfig.controlRowHeight - SettingsConfig.groupContentSpacingSm
                    opacity: controlRow.columnCount <= stepper.minValue ? SettingsConfig.faintOpacity : 1
                    radius: GlobalConfig.radiusSm
                    width: WallpaperConfig.controlRowHeight

                    Text {
                        anchors.centerIn: parent
                        color: ColorConfig.text
                        font.family: FontConfig.fontFamily
                        font.pixelSize: FontConfig.fontSettingsBody
                        text: "-"
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: controlRow.columnCount > stepper.minValue

                        onClicked: controlRow.columnCountChangeRequested(stepper.clamp(controlRow.columnCount - 1))
                    }
                }
                Rectangle {
                    id: numBox

                    border.color: numInput.activeFocus ? ColorConfig.accent : ColorConfig.textAlpha15
                    border.width: SettingsConfig.hairlineBorderWidth
                    color: ColorConfig.textAlpha07
                    height: WallpaperConfig.controlRowHeight - SettingsConfig.groupContentSpacingSm
                    radius: SettingsConfig.fieldRadius
                    width: SettingsConfig.numberFieldWidth

                    Behavior on border.color {
                        ColorAnimation {
                            duration: GlobalConfig.animationFast
                        }
                    }

                    TextInput {
                        id: numInput

                        function currentText() {
                            return controlRow.columnCount.toString();
                        }

                        anchors.fill: parent
                        anchors.margins: SettingsConfig.textFieldInset
                        color: ColorConfig.text
                        font.family: FontConfig.fontFamily
                        font.pixelSize: FontConfig.fontSettingsBody
                        horizontalAlignment: TextInput.AlignHCenter
                        selectByMouse: true
                        text: numInput.currentText()

                        validator: IntValidator {
                            bottom: stepper.minValue
                        }

                        onEditingFinished: {
                            var v = parseInt(text, 10);
                            if (!isNaN(v))
                                controlRow.columnCountChangeRequested(stepper.clamp(v));
                            numInput.text = Qt.binding(numInput.currentText);
                        }
                    }
                }
                Rectangle {
                    id: incBtn

                    color: ColorConfig.lavenderAlpha20
                    height: WallpaperConfig.controlRowHeight - SettingsConfig.groupContentSpacingSm
                    radius: GlobalConfig.radiusSm
                    width: WallpaperConfig.controlRowHeight

                    Text {
                        anchors.centerIn: parent
                        color: ColorConfig.text
                        font.family: FontConfig.fontFamily
                        font.pixelSize: FontConfig.fontSettingsBody
                        text: "+"
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: controlRow.columnCountChangeRequested(stepper.clamp(controlRow.columnCount + 1))
                    }
                }
            }
        }
        Rectangle {
            anchors.centerIn: parent
            border.color: Qt.rgba(1, 0.3, 0.3, 0.5)
            border.width: SettingsConfig.hairlineBorderWidth
            color: removeMa.containsMouse ? "#44FF5555" : "transparent"
            height: WallpaperConfig.controlRowHeight - SettingsConfig.groupContentSpacingSm
            radius: GlobalConfig.radiusSm
            visible: !!controlRow.wallpapers[controlRow.selectedScreen]
            width: removeLabel.implicitWidth + WallpaperConfig.dropdownBtnPadding

            Behavior on color {
                ColorAnimation {
                    duration: SettingsConfig.quickColorAnimMs
                }
            }

            Text {
                id: removeLabel

                anchors.centerIn: parent
                color: Qt.rgba(1, 0.4, 0.4, 1)
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontSettingsBody
                text: "Remove"
            }
            MouseArea {
                id: removeMa

                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: controlRow.wallpaperRemoved()
            }
        }
        DropdownMenu {
            activeValue: controlRow.fillModes[controlRow.selectedScreen] ?? "crop"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            disabled: !controlRow.fillModeSupported || !controlRow.wallpapers[controlRow.selectedScreen]
            height: WallpaperConfig.controlRowHeight
            labelRole: "label"
            model: WallpaperConfig.fillModes
            valueRole: "mode"

            onItemSelected: mode => controlRow.fillModeChanged(mode)
        }
    }

    component ImageGrid: Rectangle {
        id: imageGrid

        property var imageFiles: []
        property var previewSources: ({})
        property string selectedScreen: ""
        readonly property var sortedFiles: {
            var files = imageGrid.imageFiles.slice();
            files.sort(function (a, b) {
                var extA = a.split('.').pop().toLowerCase();
                var extB = b.split('.').pop().toLowerCase();
                if (extA !== extB)
                    return extA < extB ? -1 : 1;
                var nameA = a.split('/').pop().toLowerCase();
                var nameB = b.split('/').pop().toLowerCase();
                return nameA < nameB ? -1 : nameA > nameB ? 1 : 0;
            });
            return files;
        }
        property var wallpapers: ({})

        signal wallpaperSelected(string path)

        border.color: ColorConfig.accent
        border.width: GlobalConfig.borderWidthThin
        clip: true
        color: "transparent"
        radius: GlobalConfig.radiusSm + SettingsConfig.thumbnailRadiusBoost

        GridView {
            id: grid

            readonly property real cellSize: width / WallpaperConfig.imagesPerRow

            anchors.fill: parent
            anchors.margins: WallpaperConfig.gridBorderWidth
            cellHeight: cellSize
            cellWidth: cellSize
            clip: true
            model: imageGrid.sortedFiles

            // inlined WallpaperThumbnail (single use)
            delegate: Item {
                id: cell

                required property string modelData

                height: grid.cellHeight
                width: grid.cellWidth

                Rectangle {
                    id: thumb

                    anchors.fill: parent
                    anchors.margins: Math.round(grid.cellSize * SettingsConfig.thumbnailInnerMarginRatio)
                    border.color: imageGrid.wallpapers[imageGrid.selectedScreen] === cell.modelData ? ColorConfig.accentAlt : "transparent"
                    border.width: SettingsConfig.thumbnailBorderWidth
                    clip: true
                    color: ColorConfig.lavenderSubtle
                    radius: GlobalConfig.radiusSm + SettingsConfig.thumbnailRadiusBoost

                    Behavior on border.color {
                        ColorAnimation {
                            duration: SettingsConfig.quickColorAnimMs
                        }
                    }

                    Image {
                        anchors.fill: parent
                        anchors.margins: SettingsConfig.thumbnailImageInset
                        asynchronous: true
                        cache: false
                        clip: true
                        fillMode: Image.PreserveAspectCrop
                        opacity: status === Image.Ready ? 1.0 : 0.0
                        smooth: true
                        source: "file://" + (imageGrid.previewSources[cell.modelData] ?? cell.modelData)
                        sourceSize: Qt.size(width, height)

                        Behavior on opacity {
                            NumberAnimation {
                                duration: SettingsConfig.toggleAnimMs
                            }
                        }
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        color: ColorConfig.overlay
                        height: fileLabel.implicitHeight + SettingsConfig.thumbnailLabelPadding

                        Text {
                            id: fileLabel

                            anchors.left: parent.left
                            anchors.leftMargin: SettingsConfig.thumbnailLabelMargin
                            anchors.right: parent.right
                            anchors.rightMargin: SettingsConfig.thumbnailLabelMargin
                            anchors.verticalCenter: parent.verticalCenter
                            color: "white"
                            elide: Text.ElideRight
                            font.family: FontConfig.fontFamily
                            font.pixelSize: FontConfig.fontSettingsBody
                            text: cell.modelData.split('/').pop()
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onClicked: imageGrid.wallpaperSelected(cell.modelData)
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: WallpaperConfig.columnSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: WallpaperConfig.controlRowHeight

            Text {
                Layout.alignment: Qt.AlignVCenter
                color: ColorConfig.text
                font.family: FontConfig.fontFamily
                font.pixelSize: FontConfig.fontSettingsBody
                text: "Enable animated wallpaper"
            }
            Item {
                Layout.fillWidth: true
            }
            Toggle {
                Layout.alignment: Qt.AlignVCenter
                active: WallpaperService.animatedEnabled

                onToggled: WallpaperService.setAnimatedEnabled(!active)
            }
        }

        // inlined StaticWallpaperSubtab (single use)
        Item {
            id: staticSubtab

            property int selectedColumn: 0
            readonly property var selectedFillModeMap: {
                var arr = WallpaperService.staticFillModes[staticSubtab.selectedScreen] ?? [];
                var m = {};
                m[staticSubtab.selectedScreen] = arr[staticSubtab.selectedColumn] ?? "crop";
                return m;
            }
            property string selectedScreen: {
                var focusedName = HyprlandService.focusedMonitor?.name ?? "";
                if (focusedName && staticSubtab.sortedScreens.some(s => s.name === focusedName))
                    return focusedName;
                return staticSubtab.sortedScreens.length > 0 ? staticSubtab.sortedScreens[0].name : "";
            }
            readonly property var selectedWallpaperMap: {
                var arr = WallpaperService.staticWallpapers[staticSubtab.selectedScreen] ?? [];
                var m = {};
                m[staticSubtab.selectedScreen] = arr[staticSubtab.selectedColumn] ?? "";
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

            Layout.fillHeight: true
            Layout.fillWidth: true
            visible: !WallpaperService.animatedEnabled

            ColumnLayout {
                anchors.fill: parent
                spacing: WallpaperConfig.columnSpacing

                RegionRow {
                    Layout.fillWidth: true
                    Layout.preferredHeight: WallpaperConfig.controlRowHeight
                    columnsMap: WallpaperService.staticColumns
                    screens: staticSubtab.sortedScreens
                    selectedColumn: staticSubtab.selectedColumn
                    selectedScreen: staticSubtab.selectedScreen

                    onRegionSelected: (screenName, columnIndex) => {
                        staticSubtab.selectedScreen = screenName;
                        staticSubtab.selectedColumn = columnIndex;
                    }
                }
                DirBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: WallpaperConfig.dirBarHeight
                    currentDir: WallpaperService.staticDir
                    scanning: WallpaperService.staticScanning

                    onDirChangeRequested: path => WallpaperService.setStaticDir(path)
                    onEscapePressed: {}
                }
                ControlRow {
                    Layout.fillWidth: true
                    Layout.preferredHeight: WallpaperConfig.controlRowHeight
                    columnCount: WallpaperService.staticColumns[staticSubtab.selectedScreen] ?? 1
                    fillModes: staticSubtab.selectedFillModeMap
                    selectedScreen: staticSubtab.selectedScreen
                    wallpapers: staticSubtab.selectedWallpaperMap

                    onColumnCountChangeRequested: n => {
                        WallpaperService.setStaticColumns(staticSubtab.selectedScreen, n);
                        if (staticSubtab.selectedColumn >= n)
                            staticSubtab.selectedColumn = n - 1;
                    }
                    onFillModeChanged: mode => WallpaperService.setStaticFillMode(staticSubtab.selectedScreen, staticSubtab.selectedColumn, mode)
                    onWallpaperRemoved: WallpaperService.removeStaticWallpaper(staticSubtab.selectedScreen, staticSubtab.selectedColumn)
                }
                ImageGrid {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    imageFiles: WallpaperService.staticFiles
                    selectedScreen: staticSubtab.selectedScreen
                    wallpapers: staticSubtab.selectedWallpaperMap

                    onWallpaperSelected: path => WallpaperService.setStaticWallpaper(staticSubtab.selectedScreen, staticSubtab.selectedColumn, path)
                }
            }
        }

        // inlined AnimatedWallpaperSubtab (single use)
        Item {
            id: animatedSubtab

            property int selectedColumn: 0
            property string selectedScreen: {
                var focusedName = HyprlandService.focusedMonitor?.name ?? "";
                if (focusedName && animatedSubtab.sortedScreens.some(s => s.name === focusedName))
                    return focusedName;
                return animatedSubtab.sortedScreens.length > 0 ? animatedSubtab.sortedScreens[0].name : "";
            }
            readonly property var selectedVideoMap: {
                var arr = WallpaperService.animatedWallpapers[animatedSubtab.selectedScreen] ?? [];
                var m = {};
                m[animatedSubtab.selectedScreen] = arr[animatedSubtab.selectedColumn] ?? "";
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

            Layout.fillHeight: true
            Layout.fillWidth: true
            visible: WallpaperService.animatedEnabled

            ColumnLayout {
                anchors.fill: parent
                spacing: WallpaperConfig.columnSpacing

                RegionRow {
                    Layout.fillWidth: true
                    Layout.preferredHeight: WallpaperConfig.controlRowHeight
                    columnsMap: WallpaperService.animatedColumns
                    screens: animatedSubtab.sortedScreens
                    selectedColumn: animatedSubtab.selectedColumn
                    selectedScreen: animatedSubtab.selectedScreen

                    onRegionSelected: (screenName, columnIndex) => {
                        animatedSubtab.selectedScreen = screenName;
                        animatedSubtab.selectedColumn = columnIndex;
                    }
                }
                DirBar {
                    Layout.fillWidth: true
                    Layout.preferredHeight: WallpaperConfig.dirBarHeight
                    currentDir: WallpaperService.animatedDir
                    scanning: WallpaperService.animatedScanning

                    onDirChangeRequested: path => WallpaperService.setAnimatedDir(path)
                    onEscapePressed: {}
                }
                ControlRow {
                    Layout.fillWidth: true
                    Layout.preferredHeight: WallpaperConfig.controlRowHeight
                    columnCount: WallpaperService.animatedColumns[animatedSubtab.selectedScreen] ?? 1
                    fillModeSupported: false
                    selectedScreen: animatedSubtab.selectedScreen
                    wallpapers: animatedSubtab.selectedVideoMap

                    onColumnCountChangeRequested: n => {
                        WallpaperService.setAnimatedColumns(animatedSubtab.selectedScreen, n);
                        if (animatedSubtab.selectedColumn >= n)
                            animatedSubtab.selectedColumn = n - 1;
                    }
                    onWallpaperRemoved: WallpaperService.removeAnimatedWallpaper(animatedSubtab.selectedScreen, animatedSubtab.selectedColumn)
                }
                ImageGrid {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    imageFiles: WallpaperService.animatedFiles
                    previewSources: WallpaperService.animatedThumbnails
                    selectedScreen: animatedSubtab.selectedScreen
                    wallpapers: animatedSubtab.selectedVideoMap

                    onWallpaperSelected: path => WallpaperService.setAnimatedWallpaper(animatedSubtab.selectedScreen, animatedSubtab.selectedColumn, path)
                }
            }
        }
    }
}
