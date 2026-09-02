pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import qs.config

ToolTip {
    id: root

    property bool alternativeVisibleCondition: false
    property bool extraVisibleCondition: true
    readonly property bool internalVisibleCondition: alternativeVisibleCondition || (extraVisibleCondition && (!parent || parent.hovered === undefined || parent.hovered))

    background: null
    horizontalPadding: OverviewConfig.toolTipHorizontalPadding
    verticalPadding: OverviewConfig.toolTipVerticalPadding
    visible: internalVisibleCondition

    contentItem: StyledToolTipContent {
        id: contentItem

        horizontalPadding: root.horizontalPadding
        shown: root.internalVisibleCondition
        text: root.text
        verticalPadding: root.verticalPadding
    }
}
