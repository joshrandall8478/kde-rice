/*
    SPDX-FileCopyrightText: 2013-2017 Jan Grulich <jgrulich@redhat.com>

    SPDX-License-Identifier: LGPL-2.1-only OR LGPL-3.0-only OR LicenseRef-KDE-Accepted-LGPL
*/

import QtQuick 2.4
import QtQuick.Layouts 1.4
import org.kde.kcoreaddons 1.0 as KCoreAddons
import org.kde.quickcharts 1.0 as QuickCharts
import org.kde.quickcharts.controls 1.0 as QuickChartControls
import org.kde.kirigami 2.15 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.core 2.0 as PlasmaCore

ColumnLayout {
    property alias downloadSpeed: download.value
    property alias uploadSpeed: upload.value

    spacing: PlasmaCore.Units.largeSpacing

    Item {
        Layout.fillWidth: true
        implicitHeight: plotter.height + speedMetrics.height

        QuickCharts.AxisLabels {
            anchors {
                right: plotter.left
                rightMargin: PlasmaCore.Units.smallSpacing
                top: plotter.top
                bottom: plotter.bottom
            }
            constrainToBounds: false
            direction: QuickCharts.AxisLabels.VerticalBottomTop
            delegate:  PlasmaComponents3.Label {
                text: KCoreAddons.Format.formatByteSize(QuickCharts.AxisLabels.label) + i18n("/s")
                font: PlasmaCore.Theme.smallestFont
            }
            source: QuickCharts.ChartAxisSource {
                chart: plotter
                axis: QuickCharts.ChartAxisSource.YAxis
                itemCount: 5
            }
        }
        QuickCharts.GridLines {
            anchors.fill: plotter
            direction: QuickCharts.GridLines.Vertical
            minor.visible: false
            major.count: 3
            major.lineWidth: 1
            // Same calculation as Kirigami Separator
            major.color: Kirigami.ColorUtils.linearInterpolation(PlasmaCore.Theme.backgroundColor, PlasmaCore.Theme.textColor, 0.4)
        }
        QuickCharts.LineChart {
            id: plotter
            anchors {
                left: parent.left
                leftMargin: speedMetrics.width + PlasmaCore.Units.smallSpacing
                right: parent.right
                top: parent.top
                // Align plotter lines with labels.
                topMargin: speedMetrics.height / 2 + PlasmaCore.Units.smallSpacing
            }
            height: PlasmaCore.Units.gridUnit * 8
            smooth: true
            direction: QuickCharts.XYChart.ZeroAtEnd
            yRange {
                minimum: 100 * 1024
                increment: 100 * 1024
            }
            valueSources: [
                QuickCharts.ValueHistorySource {
                    id: upload
                    maximumHistory: 40
                },
                QuickCharts.ValueHistorySource {
                    id: download
                    maximumHistory: 40
                }
            ]
            nameSource: QuickCharts.ArraySource {
                array: [i18n("Upload"), i18n("Download")]
            }
            colorSource: QuickCharts.ArraySource {
                array: colors.colors.reverse()
            }
            fillColorSource: QuickCharts.ArraySource  {
                array: colors.colors.reverse().map(color => Qt.lighter(color, 1.5))
            }
            QuickCharts.ColorGradientSource {
                id: colors
                baseColor:  PlasmaCore.Theme.highlightColor
                itemCount: 2
            }
        }
        TextMetrics {
            id: speedMetrics
            font: PlasmaCore.Theme.smallestFont
            // Measure 888.8 KiB/s
            text: KCoreAddons.Format.formatByteSize(910131) + i18n("/s")
        }
    }
    QuickChartControls.Legend {
        chart: plotter
        Layout.leftMargin: PlasmaCore.Units.smallSpacing
        spacing: PlasmaCore.Units.largeSpacing
        delegate: RowLayout {
            spacing: PlasmaCore.Units.smallSpacing
            Rectangle {
                color: model.color
                width: PlasmaCore.Units.smallSpacing
                height: legendLabel.height
            }
            PlasmaComponents3.Label {
                id: legendLabel
                font: PlasmaCore.Theme.smallestFont
                text: model.name
            }
        }
    }
}
