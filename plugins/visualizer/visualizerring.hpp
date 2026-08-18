#pragma once

#include <qcolor.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qquickitem.h>
#include <qvector.h>

namespace keqingshell {

class VisualizerRing : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(
        QVector<double> values READ values WRITE setValues NOTIFY valuesChanged)
    Q_PROPERTY(QList<QColor> gradientColors READ gradientColors WRITE
                   setGradientColors NOTIFY gradientColorsChanged)
    Q_PROPERTY(qreal baseRadius READ baseRadius WRITE setBaseRadius NOTIFY
                   baseRadiusChanged)
    Q_PROPERTY(qreal maxBarHeight READ maxBarHeight WRITE setMaxBarHeight
                   NOTIFY maxBarHeightChanged)
    Q_PROPERTY(qreal barThicknessRatio READ barThicknessRatio WRITE
                   setBarThicknessRatio NOTIFY barThicknessRatioChanged)
    Q_PROPERTY(int animationDuration READ animationDuration WRITE
                   setAnimationDuration NOTIFY animationDurationChanged)
    Q_PROPERTY(bool settled READ settled NOTIFY settledChanged)

  public:
    explicit VisualizerRing(QQuickItem *parent = nullptr);

    Q_INVOKABLE void advance(qreal dt);

    [[nodiscard]] QVector<double> values() const;
    void setValues(const QVector<double> &values);

    [[nodiscard]] QList<QColor> gradientColors() const;
    void setGradientColors(const QList<QColor> &colors);

    [[nodiscard]] qreal baseRadius() const;
    void setBaseRadius(qreal radius);

    [[nodiscard]] qreal maxBarHeight() const;
    void setMaxBarHeight(qreal height);

    [[nodiscard]] qreal barThicknessRatio() const;
    void setBarThicknessRatio(qreal ratio);

    [[nodiscard]] int animationDuration() const;
    void setAnimationDuration(int duration);

    [[nodiscard]] bool settled() const;

  protected:
    QSGNode *updatePaintNode(QSGNode *oldNode,
                             UpdatePaintNodeData *updatePaintNodeData) override;

  signals:
    void valuesChanged();
    void gradientColorsChanged();
    void baseRadiusChanged();
    void maxBarHeightChanged();
    void barThicknessRatioChanged();
    void animationDurationChanged();
    void settledChanged();

  private:
    QVector<double> m_targetValues;
    QVector<double> m_displayValues;
    QList<QColor> m_gradientColors;
    qreal m_baseRadius = 60.0;
    qreal m_maxBarHeight = 60.0;
    qreal m_barThicknessRatio = 0.8;
    int m_animationDuration = 200;
    bool m_settled = true;
};

} // namespace keqingshell
