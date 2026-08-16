pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.config

ColumnLayout {
    id: root

    property int entryHeight: LauncherConfig.entryHeight
    property int innerMargins: LauncherConfig.innerMargins
    property int innerSpacing: LauncherConfig.innerSpacing
    property alias input: searchBarInst.input
    property alias list: searchResults
    property int maxVisibleEntries: LauncherConfig.maxVisibleEntries
    required property string mode
    readonly property int resultsCount: (root.resultsModel && root.resultsModel.length !== undefined) ? root.resultsModel.length : 0
    required property var resultsModel

    signal entryActivated(var modelData)
    signal queryEdited(string text)

    Layout.fillHeight: true
    Layout.fillWidth: true
    Layout.margins: innerMargins
    Layout.preferredWidth: parent.width * LauncherConfig.menuBrowseWidthRatio
    spacing: innerSpacing

    RowLayout {
        id: searchBarInst

        property alias input: input
        property string mode: root.mode
        property int size: root.entryHeight

        Layout.fillWidth: true
        spacing: LauncherConfig.searchbarSpacing

        input.onTextChanged: {
            root.queryEdited(input.text);
            searchResults.currentIndex = (root.resultsCount > 0) ? 0 : -1;
        }

        Rectangle {
            Layout.preferredHeight: searchBarInst.size
            Layout.preferredWidth: searchBarInst.size
            border.color: ColorConfig.accent
            border.width: LauncherConfig.searchbarBorderWidth
            color: "transparent"
            radius: LauncherConfig.searchbarRadius

            Text {
                anchors.centerIn: parent
                color: ColorConfig.text
                font.family: IconConfig.fontFamily
                font.pixelSize: LauncherConfig.searchbarFontPx
                text: LauncherConfig.modeIcons[searchBarInst.mode] || ""
            }
        }
        TextField {
            id: input

            Layout.fillWidth: true
            Layout.preferredHeight: searchBarInst.size
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
    ResultsList {
        id: searchResults

        Layout.preferredHeight: {
            var visible = Math.min(root.maxVisibleEntries, root.resultsCount);
            return visible * root.entryHeight;
        }
        entryHeight: root.entryHeight
        maxVisibleEntries: root.maxVisibleEntries
        resultsModel: root.resultsModel

        onEntryActivated: modelData => root.entryActivated(modelData)
    }
}
