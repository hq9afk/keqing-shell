#pragma once

#include <qcolor.h>
#include <qlist.h>
#include <algorithm>

namespace keqingshell {

// Shared by VisualizerBars
inline QColor interpolateGradient(const QList<QColor> &colors, qreal t) {
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

} // namespace keqingshell
