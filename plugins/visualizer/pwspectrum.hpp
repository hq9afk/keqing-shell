#pragma once

#include <complex>
#include <mutex>
#include <vector>

#include <pipewire/pipewire.h>
#include <spa/param/audio/format-utils.h>

#include <qlist.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qtimer.h>
#include <qtypes.h>

namespace keqingshell {

class PwSpectrum : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(int bars READ bars WRITE setBars NOTIFY barsChanged)
    Q_PROPERTY(QList<double> values READ values NOTIFY valuesChanged)
    Q_PROPERTY(bool idle READ isIdle NOTIFY idleChanged)
    Q_PROPERTY(int targetNodeId READ targetNodeId WRITE setTargetNodeId NOTIFY
                   targetNodeIdChanged)

  public:
    explicit PwSpectrum(QObject *parent = nullptr);
    ~PwSpectrum() override;

    [[nodiscard]] int bars() const;
    void setBars(int count);

    [[nodiscard]] QList<double> values() const { return m_values; }
    [[nodiscard]] bool isIdle() const { return m_idle; }

    [[nodiscard]] int targetNodeId() const { return m_targetNodeId; }
    void setTargetNodeId(int id);

    // Called every frame by QML
    Q_INVOKABLE void processFrame();

  signals:
    void barsChanged();
    void valuesChanged();
    void idleChanged();
    void targetNodeIdChanged();

  private slots:
    void doRebuild();

  private:
    void buildStream();
    void destroyStream();
    void feedSamples(const float *mono, int count);

    static void onProcess(void *data);
    static void onParamChanged(void *data, uint32_t id, const spa_pod *param);
    static void onStateChanged(void *data, pw_stream_state old,
                               pw_stream_state state, const char *err);
    static void onStreamDestroy(void *data);

    void initProcessing();
    void computeBandBins();

    int m_bars = 32;
    int m_targetNodeId = 0;
    QList<double> m_values;
    bool m_idle = true;

    // PipeWire native background thread
    pw_thread_loop *m_pwLoop = nullptr;
    pw_context *m_ctx = nullptr;
    pw_core *m_core = nullptr;
    pw_stream *m_stream = nullptr;
    pw_stream_events m_streamEvents{};
    spa_hook m_streamListener{};
    bool m_formatReady = false;
    spa_audio_info_raw m_format{};

    // Thread-safe Audio Buffer
    std::mutex m_ringMutex;
    std::vector<float> m_ringBuf;
    int m_ringPos = 0;
    bool m_ringFull = false;
    bool m_samplesReceived = false;

    QTimer m_rebuildTimer;

    // DSP & Hardware FFT state
    static constexpr int FFT_SIZE = 4096;
    static constexpr int IDLE_THRESHOLD = 30;

    int m_sampleRate = 48000;
    std::vector<float> m_window;
    std::vector<int> m_binLow;
    std::vector<int> m_binHigh;
    std::vector<float> m_prevBands;
    std::vector<float> m_peak;
    std::vector<float> m_fall;
    std::vector<float> m_bands;

    // PocketFFT Buffers
    std::vector<float> m_fftIn;
    std::vector<std::complex<float>> m_fftOut;

    float m_globalMax = 1e-3f;
    double m_gravityMod = 1.0;
    float m_noiseReduction = 0.77f;
    bool m_smoothing = true;
    int m_idleFrames = 0;
    int m_lowerCutoff = 50;
    int m_upperCutoff = 12000;
};

} // namespace keqingshell