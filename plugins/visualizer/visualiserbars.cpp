#include "visualiserbars.hpp"

#include <QSGGeometry>
#include <QSGGeometryNode>
#include <QSGVertexColorMaterial>
#include <algorithm>
#include <cmath>

namespace keqingshell {

VisualiserBars::VisualiserBars(QQuickItem *parent) : QQuickItem(parent) {
    setFlag(ItemHasContents, true);
}

void VisualiserBars::advance(qreal dt) {
    if (m_displayValues.isEmpty() || m_settled)
        return;

    const qreal dtMs = dt * 1000.0;
    const qreal tau = m_animationDuration / 3.0;
    const qreal alpha = 1.0 - std::exp(-dtMs / tau);

    bool allSettled = true;

    for (qsizetype i = 0; i < m_displayValues.size(); ++i) {
        const double diff = m_targetValues[i] - m_displayValues[i];
        if (std::abs(diff) > 0.001) {
            m_displayValues[i] += diff * alpha;
            allSettled = false;
        } else {
            m_displayValues[i] = m_targetValues[i];
        }
    }

    update();

    if (allSettled && !m_settled) {
        m_settled = true;
        emit settledChanged();
    }
}

static QColor interpolateGradient(const QList<QColor> &colors, qreal t) {
    if (colors.isEmpty())
        return Qt::white;
    if (colors.size() == 1)
        return colors[0];
    t = std::clamp(t, 0.0, 1.0);
    qreal scaled = t * (colors.size() - 1);
    int idx = static_cast<int>(scaled);
    if (idx >= colors.size() - 1)
        return colors.last();
    qreal frac = scaled - idx;
    QColor c1 = colors[idx];
    QColor c2 = colors[idx + 1];
    return QColor(c1.red() + (c2.red() - c1.red()) * frac,
                  c1.green() + (c2.green() - c1.green()) * frac,
                  c1.blue() + (c2.blue() - c1.blue()) * frac,
                  c1.alpha() + (c2.alpha() - c1.alpha()) * frac);
}

QSGNode *VisualiserBars::updatePaintNode(QSGNode *oldNode,
                                         UpdatePaintNodeData *) {
    QSGGeometryNode *node = static_cast<QSGGeometryNode *>(oldNode);
    if (!node) {
        node = new QSGGeometryNode;
        QSGGeometry *geometry =
            new QSGGeometry(QSGGeometry::defaultAttributes_ColoredPoint2D(), 0);
        geometry->setDrawingMode(QSGGeometry::DrawTriangles);
        node->setGeometry(geometry);
        node->setFlag(QSGNode::OwnsGeometry);

        QSGVertexColorMaterial *material = new QSGVertexColorMaterial;
        node->setMaterial(material);
        node->setFlag(QSGNode::OwnsMaterial);
    }

    int count = m_displayValues.size();
    if (count == 0 || width() <= 0 || height() <= 0) {
        node->geometry()->allocate(0);
        return node;
    }

    const qreal w = width();
    const qreal h = height();
    const qreal barWidth =
        (w - m_spacing * static_cast<qreal>(count - 1)) / static_cast<qreal>(count);
    const qreal slotWidth = barWidth + m_spacing;

    if (barWidth <= 0) {
        node->geometry()->allocate(0);
        return node;
    }

    QSGGeometry *geometry = node->geometry();
    geometry->allocate(count * 6);
    QSGGeometry::ColoredPoint2D *vertices =
        geometry->vertexDataAsColoredPoint2D();

    for (int i = 0; i < count; ++i) {
        const qreal value = std::clamp(m_displayValues[i], 0.0, 1.0);
        const qreal barHeight = std::max(value * h, 5.0);

        const qreal x1 = static_cast<qreal>(i) * slotWidth;
        const qreal x2 = x1 + barWidth;
        const qreal y1 = h - barHeight;
        const qreal y2 = h;

        QColor topColor = interpolateGradient(m_gradientColors, y1 / h);
        QColor bottomColor = interpolateGradient(m_gradientColors, 1.0);

        auto cTop = topColor.toRgb();
        auto cBot = bottomColor.toRgb();

        int vIdx = i * 6;
        vertices[vIdx].set(x1, y1, cTop.red(), cTop.green(), cTop.blue(),
                           cTop.alpha());
        vertices[vIdx + 1].set(x1, y2, cBot.red(), cBot.green(), cBot.blue(),
                               cBot.alpha());
        vertices[vIdx + 2].set(x2, y1, cTop.red(), cTop.green(), cTop.blue(),
                               cTop.alpha());
        vertices[vIdx + 3].set(x1, y2, cBot.red(), cBot.green(), cBot.blue(),
                               cBot.alpha());
        vertices[vIdx + 4].set(x2, y2, cBot.red(), cBot.green(), cBot.blue(),
                               cBot.alpha());
        vertices[vIdx + 5].set(x2, y1, cTop.red(), cTop.green(), cTop.blue(),
                               cTop.alpha());
    }

    node->markDirty(QSGNode::DirtyGeometry);
    return node;
}

QVector<double> VisualiserBars::values() const { return m_targetValues; }
void VisualiserBars::setValues(const QVector<double> &values) {
    m_targetValues = values;
    if (m_displayValues.size() != values.size())
        m_displayValues.resize(values.size(), 0.0);
    if (m_settled) {
        m_settled = false;
        emit settledChanged();
    }
    emit valuesChanged();
}
bool VisualiserBars::settled() const { return m_settled; }
QList<QColor> VisualiserBars::gradientColors() const {
    return m_gradientColors;
}
void VisualiserBars::setGradientColors(const QList<QColor> &colors) {
    if (m_gradientColors == colors)
        return;
    m_gradientColors = colors;
    emit gradientColorsChanged();
    update();
}
qreal VisualiserBars::rounding() const { return m_rounding; }
void VisualiserBars::setRounding(qreal rounding) { m_rounding = rounding; }
qreal VisualiserBars::spacing() const { return m_spacing; }
void VisualiserBars::setSpacing(qreal spacing) {
    if (qFuzzyCompare(m_spacing, spacing))
        return;
    m_spacing = spacing;
    emit spacingChanged();
    update();
}
int VisualiserBars::animationDuration() const { return m_animationDuration; }
void VisualiserBars::setAnimationDuration(int duration) {
    if (m_animationDuration == duration)
        return;
    m_animationDuration = duration;
    emit animationDurationChanged();
}

} // namespace keqingshell