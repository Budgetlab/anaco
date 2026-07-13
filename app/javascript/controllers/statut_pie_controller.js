import { Controller } from "@hotwired/stimulus"
import Highcharts from "highcharts"
import exporting from "exporting"
import data from "data"
import accessibility from "accessibility"
import nodata from "nodata"

exporting(Highcharts)
data(Highcharts)
accessibility(Highcharts)
nodata(Highcharts)

// Menu d'export identique au tableau de bord actes (highcharts-actes).
const EXPORT_CHART_COLORS = [
    "#6a6af4", "#000091", "#fbb8f6", "#a558a0", "#bfccfb",
    "#ca795c", "#eadecd", "#ffc4b7", "#473e29", "#73e0cf",
]

export const EXPORTING_CONFIG = {
    enabled: true,
    allowHTML: true,
    chartOptions: {
        colors: EXPORT_CHART_COLORS,
        chart: { style: { fontFamily: "Marianne" } }
    },
    buttons: {
        contextButton: {
            menuItems: ["downloadPNG", "downloadJPEG", "downloadPDF", "downloadSVG", "downloadCSV", "downloadXLS"],
            theme: { fill: 'transparent' }
        }
    },
    menuItemDefinitions: {
        downloadPNG: { text: 'Télécharger en PNG' },
        downloadJPEG: { text: 'Télécharger en JPEG' },
        downloadPDF: { text: 'Télécharger en PDF' },
        downloadSVG: { text: 'Télécharger en SVG' },
        downloadCSV: { text: 'Télécharger en CSV' },
        downloadXLS: { text: 'Télécharger en XLS' }
    }
}

const COLOR_BY_STATUT = {
    'Favorable': "var(--background-action-low-green-bourgeon)",
    'Favorable avec réserve': "var(--background-alt-green-menthe-active)",
    'Défavorable': "var(--background-action-high-red-marianne-active)",
    'Aucun risque': "var(--background-action-low-green-bourgeon)",
    'Risques éventuels ou modérés': "var(--background-alt-green-menthe-active)",
    'Risques modérés': "var(--background-alt-green-menthe-active)",
    'Risques certains ou significatifs': "var(--background-action-high-red-marianne-active)",
    'Risques significatifs': "var(--background-action-high-red-marianne-active)",
    'Non reçu': "var(--background-contrast-brown-caramel)",
    'Non renseigné': "var(--background-disabled-grey)",
}

export default class extends Controller {
    static values = {
        title: String,
        data: Array,
    }

    connect() {
        const series = [{
            name: 'Statut',
            data: this.dataValue,
        }]
        const colors = this.dataValue.map(p => COLOR_BY_STATUT[p.name] || "var(--border-action-low-beige-gris-galet)")

        const options = {
            chart: {
                type: 'pie',
                height: 600,
                style: { fontFamily: "Marianne" },
                plotBackgroundColor: null,
                plotBorderWidth: null,
                plotShadow: false,
            },
            exporting: EXPORTING_CONFIG,
            colors: colors.map(color => ({
                radialGradient: { cx: 0.5, cy: 0.3, r: 0.7 },
                stops: [[0, color], [1, Highcharts.color(color).brighten(-0.3).get('rgb')]]
            })),
            title: {
                text: this.titleValue,
                style: { fontSize: '18px', fontWeight: "900", color: 'var(--text-title-grey)' },
            },
            legend: {
                align: 'center',
                verticalAlign: 'bottom',
                layout: 'vertical',
                maxHeight: 150,
                itemMarginTop: 2,
                itemMarginBottom: 2,
                itemStyle: {
                    color: 'var(--text-title-grey)',
                    fontSize: '11px',
                    fontWeight: 'normal',
                },
            },
            tooltip: {
                borderColor: 'transparent',
                borderRadius: 16,
                backgroundColor: "rgba(245, 245, 245, 1)",
                formatter: function () {
                    return '<b>' + this.point.name + ': </b>' + this.point.y +
                        ' (' + Math.round(this.percentage * 10) / 10 + '% )';
                }
            },
            plotOptions: {
                pie: {
                    size: '100%',
                    innerSize: '80%',
                    allowPointSelect: true,
                    cursor: 'pointer',
                    dataLabels: {
                        enabled: true,
                        format: '<b>{point.y}</b>',
                        style: {
                            textOutline: '1px #FFFFFF',
                            fontSize: '11px',
                            fontWeight: 'bold',
                            color: 'var(--text-title-grey)',
                        }
                    },
                    showInLegend: true,
                }
            },
            series: series,
        }
        this.chart = Highcharts.chart(this.element, options)
        this.chart.reflow()
    }

    disconnect() {
        if (this.chart) this.chart.destroy()
    }
}
