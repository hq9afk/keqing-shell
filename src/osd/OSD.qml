pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.service
import qs.osd.layout

Scope {
    Loader {
        active: SettingsService.adapter.osd.active.indexOf("Sink") !== -1

        sourceComponent: Component {
            SinkOSD {}
        }
    }
    Loader {
        active: SettingsService.adapter.osd.active.indexOf("Source") !== -1

        sourceComponent: Component {
            SourceOSD {}
        }
    }
}
