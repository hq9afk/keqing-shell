#pragma once

#include <vector>

#include <qcolor.h>
#include <qfont.h>
#include <qimage.h>
#include <qqmlintegration.h>
#include <qquickitem.h>
#include <qsgtexture.h>
#include <qstring.h>
#include <qtimer.h>

namespace keqingshell {

class MatrixGrid : public QQuickItem {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString glyphs READ glyphs WRITE setGlyphs NOTIFY glyphsChanged)
    Q_PROPERTY(QFont font READ font WRITE setFont NOTIFY fontChanged)
    Q_PROPERTY(qreal cellWidth READ cellWidth WRITE setCellWidth NOTIFY
                   cellWidthChanged)
    Q_PROPERTY(qreal cellHeight READ cellHeight WRITE setCellHeight NOTIFY
                   cellHeightChanged)
    Q_PROPERTY(QColor headColor READ headColor WRITE setHeadColor NOTIFY
                   headColorChanged)
    Q_PROPERTY(QColor tailColor READ tailColor WRITE setTailColor NOTIFY
                   tailColorChanged)
    Q_PROPERTY(qreal fadeAlpha READ fadeAlpha WRITE setFadeAlpha NOTIFY
                   fadeAlphaChanged)
    Q_PROPERTY(int fallIntervalMs READ fallIntervalMs WRITE setFallIntervalMs
                   NOTIFY fallIntervalMsChanged)
    Q_PROPERTY(qreal resetChance READ resetChance WRITE setResetChance NOTIFY
                   resetChanceChanged)
    Q_PROPERTY(qreal boldChance READ boldChance WRITE setBoldChance NOTIFY
                   boldChanceChanged)
    Q_PROPERTY(
        bool running READ isRunning WRITE setRunning NOTIFY runningChanged)

  public:
    explicit MatrixGrid(QQuickItem *parent = nullptr);
    ~MatrixGrid() override;

    [[nodiscard]] QString glyphs() const { return m_glyphs; }
    void setGlyphs(const QString &glyphs);

    [[nodiscard]] QFont font() const { return m_font; }
    void setFont(const QFont &font);

    [[nodiscard]] qreal cellWidth() const { return m_cellWidth; }
    void setCellWidth(qreal width);

    [[nodiscard]] qreal cellHeight() const { return m_cellHeight; }
    void setCellHeight(qreal height);

    [[nodiscard]] QColor headColor() const { return m_headColor; }
    void setHeadColor(const QColor &color);

    [[nodiscard]] QColor tailColor() const { return m_tailColor; }
    void setTailColor(const QColor &color);

    [[nodiscard]] qreal fadeAlpha() const { return m_fadeAlpha; }
    void setFadeAlpha(qreal alpha);

    [[nodiscard]] int fallIntervalMs() const { return m_fallIntervalMs; }
    void setFallIntervalMs(int ms);

    [[nodiscard]] qreal resetChance() const { return m_resetChance; }
    void setResetChance(qreal chance);

    [[nodiscard]] qreal boldChance() const { return m_boldChance; }
    void setBoldChance(qreal chance);

    [[nodiscard]] bool isRunning() const { return m_running; }
    void setRunning(bool running);

  signals:
    void glyphsChanged();
    void fontChanged();
    void cellWidthChanged();
    void cellHeightChanged();
    void headColorChanged();
    void tailColorChanged();
    void fadeAlphaChanged();
    void fallIntervalMsChanged();
    void resetChanceChanged();
    void boldChanceChanged();
    void runningChanged();

  protected:
    QSGNode *updatePaintNode(QSGNode *oldNode,
                             UpdatePaintNodeData *updatePaintNodeData) override;
    void geometryChange(const QRectF &newGeometry,
                        const QRectF &oldGeometry) override;

  private slots:
    void onTick();

  private:
    // Per-column state for the accumulation-buffer rain effect.
    struct Column {
        qreal drop = 0;
        bool everReset = false;
        qreal lastHeadDrop = 0;
        QChar lastGlyph;
        bool lastHeadValid = false;
    };

    void rebuildGrid();
    void decayBuffer();
    qreal startDrop() const;
    QChar randomGlyph() const;

    QString m_glyphs;
    QFont m_font;
    qreal m_cellWidth = 16;
    qreal m_cellHeight = 18;
    QColor m_headColor = Qt::white;
    QColor m_tailColor = Qt::gray;
    qreal m_fadeAlpha = 0.05;
    int m_fallIntervalMs = 33;
    qreal m_resetChance = 0.025;
    qreal m_boldChance = 0.5;
    bool m_running = false;

    QTimer m_tickTimer;
    std::vector<Column> m_columns;
    int m_columnCount = 0;
    int m_rowCount = 0;
    qreal m_offsetX = 0;
    qreal m_offsetY = 0;

    QImage m_buffer;
    QSGTexture *m_bufferTexture = nullptr;
};

} // namespace keqingshell
