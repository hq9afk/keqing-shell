#pragma once

#include <qcolor.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qquickitem.h>
#include <qvector.h>

namespace keqingshell {

class VisualiserBars : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(
        QVector<double> values READ values WRITE setValues NOTIFY valuesChanged)
    Q_PROPERTY(QList<QColor> gradientColors READ gradientColors WRITE
                   setGradientColors NOTIFY gradientColorsChanged)
    Q_PROPERTY(
        qreal rounding READ rounding WRITE setRounding NOTIFY roundingChanged)
    Q_PROPERTY(
        qreal spacing READ spacing WRITE setSpacing NOTIFY spacingChanged)
    Q_PROPERTY(int animationDuration READ animationDuration WRITE
                   setAnimationDuration NOTIFY animationDurationChanged)
    Q_PROPERTY(bool settled READ settled NOTIFY settledChanged)

  public:
    explicit VisualiserBars(QQuickItem *parent = nullptr);

    Q_INVOKABLE void advance(qreal dt);

    [[nodiscard]] QVector<double> values() const;
    void setValues(const QVector<double> &values);

    [[nodiscard]] QList<QColor> gradientColors() const;
    void setGradientColors(const QList<QColor> &colors);

    [[nodiscard]] qreal rounding() const;
    void setRounding(qreal rounding);

    [[nodiscard]] qreal spacing() const;
    void setSpacing(qreal spacing);

    [[nodiscard]] int animationDuration() const;
    void setAnimationDuration(int duration);

    [[nodiscard]] bool settled() const;

  protected:
    QSGNode *updatePaintNode(QSGNode *oldNode,
                             UpdatePaintNodeData *updatePaintNodeData) override;

  signals:
    void valuesChanged();
    void gradientColorsChanged();
    void roundingChanged();
    void spacingChanged();
    void animationDurationChanged();
    void settledChanged();

  private:
    QVector<double> m_targetValues;
    QVector<double> m_displayValues;
    QList<QColor> m_gradientColors;
    qreal m_rounding = 0.0;
    qreal m_spacing = 0.0;
    int m_animationDuration = 200;
    bool m_settled = true;
};

} // namespace keqingshell