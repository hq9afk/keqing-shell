pragma ComponentBehavior: Bound

import QtQuick

import qs.elements
import qs.config

PanelRect {
    border.color: ColorConfig.accent
    border.width: BarConfig.panelBorderWidth
    color: ColorConfig.overlay
    radius: BarConfig.panelRadius
}
