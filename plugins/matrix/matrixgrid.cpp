#include "matrixgrid.hpp"

#include <algorithm>
#include <cmath>

#include <QSGSimpleTextureNode>
#include <qpainter.h>
#include <qquickwindow.h>
#include <qrandom.h>

namespace keqingshell {

MatrixGrid::MatrixGrid(QQuickItem *parent) : QQuickItem(parent) {
    setFlag(ItemHasContents, true);

    m_tickTimer.setInterval(m_fallIntervalMs);
    connect(&m_tickTimer, &QTimer::timeout, this, &MatrixGrid::onTick);
}

MatrixGrid::~MatrixGrid() { delete m_bufferTexture; }

void MatrixGrid::setGlyphs(const QString &glyphs) {
    if (m_glyphs == glyphs)
        return;
    m_glyphs = glyphs;
    emit glyphsChanged();
}

void MatrixGrid::setFont(const QFont &font) {
    if (m_font == font)
        return;
    m_font = font;
    emit fontChanged();
}

void MatrixGrid::setCellWidth(qreal width) {
    if (qFuzzyCompare(m_cellWidth, width))
        return;
    m_cellWidth = width;
    emit cellWidthChanged();
    rebuildGrid();
}

void MatrixGrid::setCellHeight(qreal height) {
    if (qFuzzyCompare(m_cellHeight, height))
        return;
    m_cellHeight = height;
    emit cellHeightChanged();
    rebuildGrid();
}

void MatrixGrid::setHeadColor(const QColor &color) {
    if (m_headColor == color)
        return;
    m_headColor = color;
    emit headColorChanged();
}

void MatrixGrid::setTailColor(const QColor &color) {
    if (m_tailColor == color)
        return;
    m_tailColor = color;
    emit tailColorChanged();
}

void MatrixGrid::setFadeAlpha(qreal alpha) {
    alpha = std::clamp(alpha, 0.0, 1.0);
    if (qFuzzyCompare(m_fadeAlpha, alpha))
        return;
    m_fadeAlpha = alpha;
    emit fadeAlphaChanged();
}

void MatrixGrid::setFallIntervalMs(int ms) {
    if (m_fallIntervalMs == ms)
        return;
    m_fallIntervalMs = ms;
    m_tickTimer.setInterval(m_fallIntervalMs);
    emit fallIntervalMsChanged();
}

void MatrixGrid::setResetChance(qreal chance) {
    if (qFuzzyCompare(m_resetChance, chance))
        return;
    m_resetChance = chance;
    emit resetChanceChanged();
}

void MatrixGrid::setBoldChance(qreal chance) {
    if (qFuzzyCompare(m_boldChance, chance))
        return;
    m_boldChance = chance;
    emit boldChanceChanged();
}

void MatrixGrid::setRunning(bool running) {
    if (m_running == running)
        return;
    m_running = running;
    emit runningChanged();

    if (m_running) {
        rebuildGrid(); // also (re)starts the tick timer
    } else {
        m_tickTimer.stop();
    }
}

void MatrixGrid::geometryChange(const QRectF &newGeometry,
                                const QRectF &oldGeometry) {
    QQuickItem::geometryChange(newGeometry, oldGeometry);

    if (newGeometry.size() == oldGeometry.size())
        return; // pure move — no dimension change, nothing to do

    if (m_cellWidth <= 0 || m_cellHeight <= 0)
        return;

    const int newColumnCount =
        std::max(1, static_cast<int>(width() / (m_cellWidth * 2)));
    const int newRowCount =
        std::max(1, static_cast<int>(height() / m_cellHeight));

    // Reset when the cell count changes
    if (newColumnCount != m_columnCount || newRowCount != m_rowCount)
        rebuildGrid();
}

qreal MatrixGrid::startDrop() const {
    // Flat wavefront
    return -2;
}

QChar MatrixGrid::randomGlyph() const {
    if (m_glyphs.isEmpty())
        return QChar(' ');
    return m_glyphs.at(
        static_cast<int>(QRandomGenerator::global()->bounded(m_glyphs.size())));
}

void MatrixGrid::rebuildGrid() {
    if (m_cellWidth <= 0 || m_cellHeight <= 0)
        return;

    // Leave a gap between streams; filling every cell reads as too dense.
    m_columnCount = std::max(1, static_cast<int>(width() / (m_cellWidth * 2)));
    m_rowCount = std::max(1, static_cast<int>(height() / m_cellHeight));

    m_columns.assign(m_columnCount, Column{});
    for (auto &column : m_columns)
        column.drop = startDrop();

    // Center the grid; content width excludes the gap after the last column.
    const qreal contentWidth = m_columnCount * m_cellWidth * 2 - m_cellWidth;
    m_offsetX = (width() - contentWidth) / 2.0;
    m_offsetY = (height() - m_rowCount * m_cellHeight) / 2.0;

    const int pixelWidth = std::max(1, static_cast<int>(std::ceil(width())));
    const int pixelHeight = std::max(1, static_cast<int>(std::ceil(height())));
    m_buffer =
        QImage(pixelWidth, pixelHeight, QImage::Format_ARGB32_Premultiplied);
    m_buffer.fill(Qt::transparent);

    if (m_running)
        m_tickTimer.start();

    update();
}

void MatrixGrid::decayBuffer() {
    // Linear, subtractive alpha decay on the premultiplied buffer.
    const int alphaStep =
        std::clamp(static_cast<int>(255 * m_fadeAlpha), 1, 255);

    const int height = m_buffer.height();
    const int width = m_buffer.width();
    for (int y = 0; y < height; y++) {
        auto *line = reinterpret_cast<QRgb *>(m_buffer.scanLine(y));
        for (int x = 0; x < width; x++) {
            const QRgb pixel = line[x];
            const int oldAlpha = qAlpha(pixel);
            if (oldAlpha == 0)
                continue;

            const int newAlpha = std::max(0, oldAlpha - alphaStep);
            if (newAlpha == 0) {
                line[x] = 0;
                continue;
            }

            // Rescale premultiplied channels to match the new alpha.
            line[x] = qRgba(qRed(pixel) * newAlpha / oldAlpha,
                            qGreen(pixel) * newAlpha / oldAlpha,
                            qBlue(pixel) * newAlpha / oldAlpha, newAlpha);
        }
    }
}

void MatrixGrid::onTick() {
    if (m_buffer.isNull() || m_columns.empty())
        return;

    decayBuffer();

    QPainter painter(&m_buffer);
    painter.setRenderHint(QPainter::TextAntialiasing, false);

    QFont regularFont = m_font;
    regularFont.setBold(false);
    QFont boldFont = m_font;
    boldFont.setBold(true);

    for (int c = 0; c < m_columnCount; c++) {
        Column &column = m_columns[c];
        const qreal x = m_offsetX + c * m_cellWidth * 2;

        if (column.lastHeadValid) {
            const qreal lastY = m_offsetY + column.lastHeadDrop * m_cellHeight;
            painter.setFont(regularFont);
            painter.setPen(m_tailColor);
            painter.drawText(
                QRectF(std::round(x), std::round(lastY), m_cellWidth,
                       m_cellHeight),
                Qt::AlignCenter, QString(column.lastGlyph));
        }

        if (column.drop >= 0) {
            const qreal y = m_offsetY + column.drop * m_cellHeight;
            const bool bold =
                QRandomGenerator::global()->generateDouble() < m_boldChance;
            const QChar glyph = randomGlyph();
            painter.setFont(bold ? boldFont : regularFont);
            painter.setPen(m_headColor);
            painter.drawText(QRectF(std::round(x), std::round(y), m_cellWidth,
                                    m_cellHeight),
                             Qt::AlignCenter, QString(glyph));

            column.lastGlyph = glyph;
            column.lastHeadDrop = column.drop;
            column.lastHeadValid = true;
        } else {
            column.lastHeadValid = false;
        }

        column.drop += 1;

        if (column.drop * m_cellHeight > height() &&
            QRandomGenerator::global()->generateDouble() < m_resetChance) {
            column.drop = column.everReset
                              ? -QRandomGenerator::global()->bounded(m_rowCount)
                              : startDrop();
            column.everReset = true;
            column.lastHeadValid = false;
        }
    }

    painter.end();

    delete m_bufferTexture;
    m_bufferTexture = window()->createTextureFromImage(m_buffer);

    update();
}

QSGNode *MatrixGrid::updatePaintNode(QSGNode *oldNode, UpdatePaintNodeData *) {
    // Nothing to paint yet (first tick hasn't built a texture) — don't hand
    // the renderer a node with no texture bound.
    if (!m_bufferTexture) {
        delete oldNode;
        return nullptr;
    }

    auto *node = static_cast<QSGSimpleTextureNode *>(oldNode);
    if (!node) {
        node = new QSGSimpleTextureNode;
        node->setFiltering(QSGTexture::Linear);
    }

    // MatrixGrid owns the texture and replaces it every tick
    node->setTexture(m_bufferTexture);
    node->setRect(0, 0, width(), height());

    return node;
}

} // namespace keqingshell
