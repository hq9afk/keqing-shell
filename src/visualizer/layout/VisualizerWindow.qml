pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

import KeqingShell.Visualizer

import qs.visualizer

FloatingWindow {
    id: window

    readonly property int barCount: Math.max(1, Math.floor((content.width - VisualizerConfig.barSpacing) / (VisualizerConfig.barWidth + VisualizerConfig.barSpacing)))
    required property bool isOpen

    color: VisualizerConfig.windowBackground
    implicitHeight: VisualizerConfig.defaultWindowHeight
    implicitWidth: VisualizerConfig.barCount * VisualizerConfig.barWidth + (VisualizerConfig.barCount - 1) * VisualizerConfig.barSpacing
    visible: content.opacity > 0 || window.isOpen

    // Spectrum
    PwSpectrum {
        id: spectrum

        bars: window.barCount
        targetNodeId: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.id : 0
    }
    FrameAnimation {
        running: true

        onTriggered: spectrum.processFrame()
    }
    Item {
        id: content

        anchors.fill: parent
        opacity: window.isOpen ? VisualizerConfig.visibleOpacity : VisualizerConfig.hiddenOpacity

        Behavior on opacity {
            NumberAnimation {
                duration: VisualizerConfig.contentFadeAnimMs
                easing.type: Easing.OutCubic

                onRunningChanged: {
                    if (!running && !window.isOpen && content.opacity === 0)
                        window.closed();
                }
            }
        }

        VisualiserBars {
            id: bars

            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.leftMargin: VisualizerConfig.barSpacing
            anchors.right: parent.right
            anchors.rightMargin: VisualizerConfig.barSpacing
            animationDuration: VisualizerConfig.barsAnimDurationMs
            gradientColors: VisualizerConfig.barGradient
            height: content.height * VisualizerConfig.barHeightRatio
            opacity: VisualizerConfig.barOpacity
            rounding: VisualizerConfig.barRadius
            spacing: VisualizerConfig.barSpacing
            values: spectrum.values

            FrameAnimation {
                running: !bars.settled

                onTriggered: bars.advance(frameTime)
            }
        }
    }
}
