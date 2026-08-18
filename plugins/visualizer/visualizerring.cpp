#include "visualizerring.hpp"

#include "gradientinterp.hpp"

#include <QSGGeometry>
#include <QSGGeometryNode>
#include <QSGVertexColorMaterial>
#include <algorithm>
#include <cmath>

namespace keqingshell {

VisualizerRing::VisualizerRing(QQuickItem *parent) : QQuickItem(parent) {
    setFlag(ItemHasContents, true);
}

void VisualizerRing::advance(qreal dt) {
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

QSGNode *VisualizerRing::updatePaintNode(QSGNode *oldNode,
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

    const int count = m_displayValues.size();
    if (count == 0 || width() <= 0 || height() <= 0) {
        node->geometry()->allocate(0);
        return node;
    }

    const qreal cx = width() / 2.0;
    const qreal cy = height() / 2.0;
    const qreal angleStep = (2.0 * M_PI) / static_cast<qreal>(count);
    const qreal angleThickness = angleStep * std::clamp(m_barThicknessRatio, 0.01, 1.0);

    QSGGeometry *geometry = node->geometry();
    geometry->allocate(count * 6);
    QSGGeometry::ColoredPoint2D *vertices =
        geometry->vertexDataAsColoredPoint2D();

    for (int i = 0; i < count; ++i) {
        const qreal value = std::clamp(m_displayValues[i], 0.0, 1.0);
        const qreal outerRadius = m_baseRadius + std::max(value * m_maxBarHeight, 2.0);

        const qreal angle1 = static_cast<qreal>(i) * angleStep;
        const qreal angle2 = angle1 + angleThickness;

        const qreal innerX1 = cx + std::cos(angle1) * m_baseRadius;
        const qreal innerY1 = cy + std::sin(angle1) * m_baseRadius;
        const qreal innerX2 = cx + std::cos(angle2) * m_baseRadius;
        const qreal innerY2 = cy + std::sin(angle2) * m_baseRadius;

        const qreal outerX1 = cx + std::cos(angle1) * outerRadius;
        const qreal outerY1 = cy + std::sin(angle1) * outerRadius;
        const qreal outerX2 = cx + std::cos(angle2) * outerRadius;
        const qreal outerY2 = cy + std::sin(angle2) * outerRadius;

        QColor innerColor = interpolateGradient(m_gradientColors, 0.0);
        QColor outerColor = interpolateGradient(m_gradientColors, value);

        auto cIn = innerColor.toRgb();
        auto cOut = outerColor.toRgb();

        const int vIdx = i * 6;
        vertices[vIdx].set(innerX1, innerY1, cIn.red(), cIn.green(), cIn.blue(),
                           cIn.alpha());
        vertices[vIdx + 1].set(outerX1, outerY1, cOut.red(), cOut.green(),
                               cOut.blue(), cOut.alpha());
        vertices[vIdx + 2].set(innerX2, innerY2, cIn.red(), cIn.green(),
                               cIn.blue(), cIn.alpha());
        vertices[vIdx + 3].set(outerX1, outerY1, cOut.red(), cOut.green(),
                               cOut.blue(), cOut.alpha());
        vertices[vIdx + 4].set(outerX2, outerY2, cOut.red(), cOut.green(),
                               cOut.blue(), cOut.alpha());
        vertices[vIdx + 5].set(innerX2, innerY2, cIn.red(), cIn.green(),
                               cIn.blue(), cIn.alpha());
    }

    node->markDirty(QSGNode::DirtyGeometry);
    return node;
}

QVector<double> VisualizerRing::values() const { return m_targetValues; }
void VisualizerRing::setValues(const QVector<double> &values) {
    m_targetValues = values;
    if (m_displayValues.size() != values.size())
        m_displayValues.resize(values.size(), 0.0);
    if (m_settled) {
        m_settled = false;
        emit settledChanged();
    }
    emit valuesChanged();
}
bool VisualizerRing::settled() const { return m_settled; }
QList<QColor> VisualizerRing::gradientColors() const {
    return m_gradientColors;
}
void VisualizerRing::setGradientColors(const QList<QColor> &colors) {
    if (m_gradientColors == colors)
        return;
    m_gradientColors = colors;
    emit gradientColorsChanged();
    update();
}
qreal VisualizerRing::baseRadius() const { return m_baseRadius; }
void VisualizerRing::setBaseRadius(qreal radius) {
    if (qFuzzyCompare(m_baseRadius, radius))
        return;
    m_baseRadius = radius;
    emit baseRadiusChanged();
    update();
}
qreal VisualizerRing::maxBarHeight() const { return m_maxBarHeight; }
void VisualizerRing::setMaxBarHeight(qreal height) {
    if (qFuzzyCompare(m_maxBarHeight, height))
        return;
    m_maxBarHeight = height;
    emit maxBarHeightChanged();
    update();
}
qreal VisualizerRing::barThicknessRatio() const { return m_barThicknessRatio; }
void VisualizerRing::setBarThicknessRatio(qreal ratio) {
    if (qFuzzyCompare(m_barThicknessRatio, ratio))
        return;
    m_barThicknessRatio = ratio;
    emit barThicknessRatioChanged();
    update();
}
int VisualizerRing::animationDuration() const { return m_animationDuration; }
void VisualizerRing::setAnimationDuration(int duration) {
    if (m_animationDuration == duration)
        return;
    m_animationDuration = duration;
    emit animationDurationChanged();
}

} // namespace keqingshell
