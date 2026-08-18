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

                    function bandAverage(values, start, end) {
                        if (!values || values.length === 0)
                            return 0;
                        const n = values.length;
                        const s = Math.max(0, Math.min(n, Math.floor(n * start)));
                        const e = Math.max(s + 1, Math.min(n, Math.floor(n * end)));
                        let sum = 0;
                        for (let i = s; i < e; i++)
                            sum += values[i];
                        return sum / (e - s);
                    }

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
                        visible: VisualizerConfig.mode === "bars"

                        FrameAnimation {
                            running: !bars.settled

                            onTriggered: bars.advance(frameTime)
                        }
                    }
                    ShaderEffect {
                        id: sphere

                        property real bassEnergy: content.bandAverage(spectrum.values, 0, 1 / 3)
                        property color colorFar: VisualizerConfig.sphereGradient[VisualizerConfig.sphereGradient.length - 1]
                        property color colorNear: VisualizerConfig.sphereGradient[0]
                        property real feather: VisualizerConfig.sphereFeather
                        property real noiseAmplitude: VisualizerConfig.sphereNoiseAmplitude
                        property real noiseFrequency: VisualizerConfig.sphereNoiseFrequency
                        property real noiseTime: 0
                        property real radiusAudioMultiplier: VisualizerConfig.sphereRadiusAudioMultiplier
                        property vector2d resolution: Qt.vector2d(width, height)
                        property real sphereRadius: VisualizerConfig.sphereRadius
                        property real trebleEnergy: content.bandAverage(spectrum.values, 2 / 3, 1)

                        anchors.fill: parent
                        fragmentShader: "qrc:/KeqingShell/Visualizer/shaders/spheresdf.frag.qsb"
                        opacity: VisualizerConfig.sphereOpacity
                        visible: VisualizerConfig.mode === "sphere"

                        FrameAnimation {
                            running: sphere.visible

                            onTriggered: sphere.noiseTime += frameTime * VisualizerConfig.sphereNoiseSpeed
                        }
                    }
                    VisualizerRing {
                        id: ring

                        anchors.centerIn: parent
                        animationDuration: VisualizerConfig.ringAnimDurationMs
                        barThicknessRatio: VisualizerConfig.ringBarThicknessRatio
                        baseRadius: VisualizerConfig.ringBaseRadius
                        gradientColors: VisualizerConfig.ringGradient
                        height: content.height
                        maxBarHeight: VisualizerConfig.ringMaxBarHeight
                        opacity: VisualizerConfig.ringOpacity
                        values: spectrum.values.concat(spectrum.values.slice().reverse())
                        visible: VisualizerConfig.mode === "ring"
                        width: content.width

                        FrameAnimation {
                            running: !ring.settled

                            onTriggered: ring.advance(frameTime)
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
