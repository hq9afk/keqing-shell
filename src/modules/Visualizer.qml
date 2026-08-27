pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

import KeqingShell.Visualizer

import qs.modules
import qs.config

ModuleLoader {
    id: root

    module: "visualizer"

    sourceComp: Component {
        Scope {
            id: panel

            property alias controller: controller

            signal closeRequested

            // Controller
            Item {
                id: controller

                property bool isOpen: false

                function close() {
                    isOpen = false;
                }
                function open() {
                    isOpen = true;
                }
                function toggle() {
                    if (isOpen)
                        close();
                    else
                        open();
                }
            }

            // Window
            FloatingWindow {
                id: window

                readonly property int barCount: Math.max(1, Math.floor((content.width - VisualizerConfig.barSpacing) / (VisualizerConfig.barWidth + VisualizerConfig.barSpacing)))
                property bool isOpen: controller.isOpen

                color: VisualizerConfig.windowBackground
                implicitHeight: VisualizerConfig.defaultWindowHeight
                implicitWidth: VisualizerConfig.barCount * VisualizerConfig.barWidth + (VisualizerConfig.barCount - 1) * VisualizerConfig.barSpacing
                visible: content.opacity > 0 || window.isOpen

                onClosed: panel.closeRequested()

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

                    VisualizerBars {
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
        }
    }

    IpcHandler {
        function toggle() {
            root.toggle();
        }

        target: "visualizer"
    }
}
