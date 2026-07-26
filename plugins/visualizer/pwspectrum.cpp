#include "pwspectrum.hpp"
#include "pocketfft_hdronly.h"

#include <algorithm>
#include <array>
#include <cmath>
#include <numbers>

#include <qloggingcategory.h>

Q_LOGGING_CATEGORY(lcSpectrum, "keqingshell.spectrum", QtInfoMsg)

namespace keqingshell {

PwSpectrum::PwSpectrum(QObject *parent) : QObject(parent) {
    initProcessing();

    m_rebuildTimer.setSingleShot(true);
    m_rebuildTimer.setInterval(500);
    QObject::connect(&m_rebuildTimer, &QTimer::timeout, this,
                     &PwSpectrum::doRebuild);

    pw_init(nullptr, nullptr);

    m_pwLoop = pw_thread_loop_new("pw-visualizer", nullptr);
    if (!m_pwLoop) {
        qCWarning(lcSpectrum) << "failed to create pw_thread_loop";
        return;
    }

    m_ctx = pw_context_new(pw_thread_loop_get_loop(m_pwLoop), nullptr, 0);
    m_core = pw_context_connect(m_ctx, nullptr, 0);

    buildStream();
    pw_thread_loop_start(m_pwLoop);
}

PwSpectrum::~PwSpectrum() {
    m_rebuildTimer.stop();

    if (m_pwLoop) {
        pw_thread_loop_stop(m_pwLoop);
    }
    if (m_stream) {
        spa_hook_remove(&m_streamListener);
        pw_stream_destroy(m_stream);
    }
    if (m_core)
        pw_core_disconnect(m_core);
    if (m_ctx)
        pw_context_destroy(m_ctx);
    if (m_pwLoop)
        pw_thread_loop_destroy(m_pwLoop);
    pw_deinit();
}

int PwSpectrum::bars() const { return m_bars; }

void PwSpectrum::setBars(int count) {
    count = std::clamp(count, 1, FFT_SIZE / 2);
    if (count == m_bars)
        return;
    m_bars = count;
    initProcessing();
    emit barsChanged();
    emit valuesChanged();
}

void PwSpectrum::setTargetNodeId(int id) {
    if (m_targetNodeId == id)
        return;
    m_targetNodeId = id;
    emit targetNodeIdChanged();
    m_rebuildTimer.start();
}

void PwSpectrum::buildStream() {
    auto *props = pw_properties_new(
        PW_KEY_MEDIA_TYPE, "Audio", PW_KEY_MEDIA_CATEGORY, "Monitor",
        PW_KEY_MEDIA_NAME, "Spectrum analyzer", PW_KEY_STREAM_MONITOR, "true",
        PW_KEY_STREAM_CAPTURE_SINK, "true", PW_KEY_NODE_PASSIVE, "true",
        nullptr);

    if (m_targetNodeId > 0)
        pw_properties_setf(props, PW_KEY_TARGET_OBJECT, "%d", m_targetNodeId);

    pw_thread_loop_lock(m_pwLoop);

    m_stream = pw_stream_new(m_core, "keqing-spectrum", props);
    m_streamEvents = {};
    m_streamEvents.version = PW_VERSION_STREAM_EVENTS;
    m_streamEvents.destroy = onStreamDestroy;
    m_streamEvents.state_changed = onStateChanged;
    m_streamEvents.param_changed = onParamChanged;
    m_streamEvents.process = onProcess;
    pw_stream_add_listener(m_stream, &m_streamListener, &m_streamEvents, this);

    std::array<uint8_t, 512> buf{};
    spa_pod_builder b;
    spa_pod_builder_init(&b, buf.data(), static_cast<uint32_t>(buf.size()));
    spa_audio_info_raw raw{};
    raw.format = SPA_AUDIO_FORMAT_F32;
    const spa_pod *params[1];
    params[0] = spa_format_audio_raw_build(&b, SPA_PARAM_EnumFormat, &raw);

    pw_stream_connect(m_stream, PW_DIRECTION_INPUT, PW_ID_ANY,
                      static_cast<pw_stream_flags>(PW_STREAM_FLAG_AUTOCONNECT |
                                                   PW_STREAM_FLAG_MAP_BUFFERS),
                      params, 1);

    pw_thread_loop_unlock(m_pwLoop);
}

void PwSpectrum::destroyStream() {
    if (!m_stream)
        return;
    pw_thread_loop_lock(m_pwLoop);
    spa_hook_remove(&m_streamListener);
    pw_stream_destroy(m_stream);
    m_stream = nullptr;
    m_formatReady = false;
    pw_thread_loop_unlock(m_pwLoop);
}

void PwSpectrum::doRebuild() {
    destroyStream();
    {
        std::lock_guard<std::mutex> lock(m_ringMutex);
        m_ringPos = 0;
        m_ringFull = false;
        m_samplesReceived = false;
    }
    buildStream();

    std::fill(m_prevBands.begin(), m_prevBands.end(), 0.0f);
    std::fill(m_peak.begin(), m_peak.end(), 0.0f);
    std::fill(m_fall.begin(), m_fall.end(), 0.0f);
    m_globalMax = 1e-3f;
    m_idleFrames = 0;
}

void PwSpectrum::onProcess(void *data) {
    auto *self = static_cast<PwSpectrum *>(data);
    if (!self->m_formatReady || !self->m_stream)
        return;

    auto *buf = pw_stream_dequeue_buffer(self->m_stream);
    if (!buf)
        return;

    auto *sbuf = buf->buffer;
    if (sbuf && sbuf->n_datas > 0) {
        auto *d = &sbuf->datas[0];
        auto channels = static_cast<int>(self->m_format.channels);

        if (d->data && d->chunk && channels > 0) {
            const auto *base =
                static_cast<const uint8_t *>(d->data) + d->chunk->offset;
            const auto *samples = reinterpret_cast<const float *>(base);
            int frames =
                static_cast<int>(d->chunk->size / sizeof(float)) / channels;

            if (frames > 0) {
                static thread_local std::vector<float> mono;
                mono.resize(frames);

                if (channels == 1) {
                    std::copy(samples, samples + frames, mono.begin());
                } else {
                    float inv = 1.0f / static_cast<float>(channels);
                    for (int i = 0; i < frames; i++) {
                        float sum = 0.0f;
                        for (int c = 0; c < channels; c++)
                            sum += samples[i * channels + c];
                        mono[i] = sum * inv;
                    }
                }
                self->feedSamples(mono.data(), frames);
            }
        }
    }
    pw_stream_queue_buffer(self->m_stream, buf);
}

void PwSpectrum::feedSamples(const float *mono, int count) {
    std::lock_guard<std::mutex> lock(m_ringMutex);
    for (int i = 0; i < count; i++) {
        m_ringBuf[m_ringPos] = mono[i];
        m_ringPos = (m_ringPos + 1) % FFT_SIZE;
        if (m_ringPos == 0)
            m_ringFull = true;
    }
    m_samplesReceived = true;
}

void PwSpectrum::onParamChanged(void *data, uint32_t id, const spa_pod *param) {
    auto *self = static_cast<PwSpectrum *>(data);
    if (!param || id != SPA_PARAM_Format)
        return;

    spa_audio_info info{};
    if (spa_format_parse(param, &info.media_type, &info.media_subtype) < 0)
        return;
    if (info.media_type != SPA_MEDIA_TYPE_audio ||
        info.media_subtype != SPA_MEDIA_SUBTYPE_raw)
        return;

    spa_audio_info_raw raw{};
    if (spa_format_audio_raw_parse(param, &raw) < 0 ||
        raw.format != SPA_AUDIO_FORMAT_F32 || raw.channels == 0)
        return;

    self->m_format = raw;
    self->m_formatReady = true;
    self->m_sampleRate = static_cast<int>(raw.rate);
    self->computeBandBins();
}

void PwSpectrum::onStateChanged(void *data, pw_stream_state,
                                pw_stream_state state, const char *err) {
    auto *self = static_cast<PwSpectrum *>(data);
    if (state == PW_STREAM_STATE_ERROR) {
        qCWarning(lcSpectrum) << "stream error:" << (err ? err : "unknown");
        QMetaObject::invokeMethod(&self->m_rebuildTimer, "start",
                                  Qt::QueuedConnection);
    }
}

void PwSpectrum::onStreamDestroy(void *data) {
    auto *self = static_cast<PwSpectrum *>(data);
    self->m_stream = nullptr;
    self->m_formatReady = false;
}

void PwSpectrum::initProcessing() {
    m_ringBuf.resize(FFT_SIZE, 0.0f);

    // PocketFFT Buffers
    m_fftIn.resize(FFT_SIZE, 0.0f);
    m_fftOut.resize(FFT_SIZE / 2 + 1);

    m_window.resize(FFT_SIZE);
    for (int i = 0; i < FFT_SIZE; i++) {
        m_window[i] =
            0.5f * (1.0f - std::cos(2.0f * std::numbers::pi_v<float> *
                                    static_cast<float>(i) /
                                    static_cast<float>(FFT_SIZE - 1)));
    }

    m_prevBands.assign(m_bars, 0.0f);
    m_peak.assign(m_bars, 0.0f);
    m_fall.assign(m_bars, 0.0f);
    m_globalMax = 1e-3f;
    m_bands.assign(m_bars, 0.0f);
    m_values = QList<double>(m_bars, 0.0);
    computeBandBins();
}

void PwSpectrum::computeBandBins() {
    m_binLow.resize(m_bars);
    m_binHigh.resize(m_bars);

    float fLow = static_cast<float>(m_lowerCutoff);
    float fHigh = static_cast<float>(std::min(m_upperCutoff, m_sampleRate / 2));
    float ratio = fHigh / fLow;
    int fftBins = FFT_SIZE / 2;

    for (int i = 0; i < m_bars; i++) {
        auto freqLow = fLow * std::pow(ratio, static_cast<float>(i) /
                                                  static_cast<float>(m_bars));
        auto freqHigh = fLow * std::pow(ratio, static_cast<float>(i + 1) /
                                                   static_cast<float>(m_bars));
        auto binLow =
            static_cast<int>(std::ceil(freqLow * static_cast<float>(FFT_SIZE) /
                                       static_cast<float>(m_sampleRate)));
        auto binHigh = static_cast<int>(
            std::floor(freqHigh * static_cast<float>(FFT_SIZE) /
                       static_cast<float>(m_sampleRate)));

        binLow = std::clamp(binLow, 1, fftBins);
        binHigh = std::clamp(binHigh, binLow, fftBins);
        if (i > 0 && binLow <= m_binHigh[i - 1]) {
            binLow = m_binHigh[i - 1] + 1;
            if (binLow > fftBins)
                binLow = fftBins;
            if (binHigh < binLow)
                binHigh = binLow;
        }
        m_binLow[i] = binLow;
        m_binHigh[i] = binHigh;
    }
}

void PwSpectrum::processFrame() {
    {
        std::lock_guard<std::mutex> lock(m_ringMutex);
        if (!m_ringFull || (m_idle && !m_samplesReceived))
            return;

        if (!m_samplesReceived) {
            for (auto &s : m_ringBuf)
                s *= 0.85f;
        }
        m_samplesReceived = false;

        for (int i = 0; i < FFT_SIZE; i++) {
            int idx = (m_ringPos + i) % FFT_SIZE;
            m_fftIn[i] = m_ringBuf[idx] * m_window[i];
        }
    }

    // Fire PocketFFT hardware acceleration
    pocketfft::shape_t shape = {static_cast<size_t>(FFT_SIZE)};
    pocketfft::stride_t stride_in = {sizeof(float)};
    pocketfft::stride_t stride_out = {sizeof(std::complex<float>)};
    pocketfft::shape_t axes = {0};

    pocketfft::r2c(shape, stride_in, stride_out, axes, pocketfft::FORWARD,
                   m_fftIn.data(), m_fftOut.data(), 1.0f);

    auto &bands = m_bands;
    float currentFrameMax = 1e-5f;

    for (int i = 0; i < m_bars; i++) {
        float maxMagSq = 0.0f;
        for (int bin = m_binLow[i]; bin <= m_binHigh[i]; bin++) {
            // Compare squared magnitudes; sqrt once below avoids doing it per bin.
            float magSq = std::norm(m_fftOut[bin]);
            if (magSq > maxMagSq)
                maxMagSq = magSq;
        }
        float mag = std::sqrt(maxMagSq);

        float freqScale = static_cast<float>(i) /
                          static_cast<float>(m_bars > 1 ? m_bars - 1 : 1);
        mag *= (2.5f + freqScale * 4.0f);
        if (freqScale <= 0.15f)
            mag *= 1.3f;

        bands[i] = mag;
        if (mag > currentFrameMax)
            currentFrameMax = mag;
    }

    m_globalMax = std::max(m_globalMax * 0.995f, currentFrameMax);
    float noiseGate = m_noiseReduction * 0.01f;

    for (int i = 0; i < m_bars; i++) {
        bands[i] = std::clamp((bands[i] / m_globalMax) - noiseGate, 0.0f, 1.0f);
    }

    if (m_smoothing) {
        constexpr float DROP_OFF = 0.66f;
        for (int i = 1; i < m_bars; i++)
            bands[i] = std::max(bands[i], bands[i - 1] * DROP_OFF);
        for (int i = m_bars - 2; i >= 0; i--)
            bands[i] = std::max(bands[i], bands[i + 1] * DROP_OFF);
    }

    bool silence = true;

    // Use 60 FPS as base for gravity mod scaling
    double fps = 60.0;
    m_gravityMod = std::pow(60.0 / fps, 2.5) * 1.54 /
                   std::max(static_cast<double>(m_noiseReduction), 0.01);
    if (m_gravityMod < 1.0)
        m_gravityMod = 1.0;

    for (int i = 0; i < m_bars; i++) {
        if (bands[i] < m_prevBands[i]) {
            bands[i] = std::max(
                static_cast<float>(static_cast<double>(m_peak[i]) *
                                   (1.0 - static_cast<double>(m_fall[i]) *
                                              static_cast<double>(m_fall[i]) *
                                              m_gravityMod)),
                0.0f);
            m_fall[i] += 0.028f;
        } else {
            m_peak[i] = bands[i];
            m_fall[i] = 0.0f;
            bands[i] = m_prevBands[i] + (bands[i] - m_prevBands[i]) * 0.6f;
        }
        m_prevBands[i] = bands[i];
        if (bands[i] > 0.01f)
            silence = false;
    }

    if (silence) {
        m_idleFrames++;
        if (m_idleFrames >= IDLE_THRESHOLD) {
            if (!m_idle) {
                m_idle = true;
                std::fill(m_values.begin(), m_values.end(), 0.0);
                emit valuesChanged();
                emit idleChanged();
            }
            return;
        }
    } else {
        m_idleFrames = 0;
        if (m_idle) {
            m_idle = false;
            emit idleChanged();
        }
    }

    bool changed = false;
    for (int i = 0; i < m_bars; i++) {
        double v = static_cast<double>(bands[i]);
        if (m_values[i] != v) {
            m_values[i] = v;
            changed = true;
        }
    }
    if (changed)
        emit valuesChanged();
}

} // namespace keqingshell