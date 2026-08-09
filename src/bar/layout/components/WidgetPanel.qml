pragma ComponentBehavior: Bound

import QtQuick

import qs.components
import qs.bar
import qs.config

PanelRect {
    border.color: ColorConfig.accent
    border.width: BarConfig.panelBorderWidth
    color: ColorConfig.overlay
    radius: BarConfig.panelRadius
}
