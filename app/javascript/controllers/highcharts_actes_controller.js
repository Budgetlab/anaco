import {Controller} from "@hotwired/stimulus"
import Highcharts from "highcharts"
import exporting from "exporting"
import data from "data"
import accessibility from "accessibility"
import nodata from "nodata"
import more from "highcharts-more"

exporting(Highcharts)
data(Highcharts)
accessibility(Highcharts)
nodata(Highcharts)
more(Highcharts)

export default class extends Controller {
    static targets = ["chart"]
    static values = {
        title: String,
        type: { type: String, default: 'pie' },
        data: Array,  // Déclarez la value ici
        dataset: Object
    }

    static CHART_COLORS = [
        "var(--border-default-blue-france)",
        "var(--background-flat-blue-france)",
        "var(--border-action-low-purple-glycine)",
        "var(--border-default-purple-glycine)",
        "var(--border-action-low-blue-ecume)",
        "var(--pink-macaron-sun-406-moon-833-hover)",
        "var(--background-alt-beige-gris-galet-hover)",
        "var(--pink-tuile-sun-425-moon-750-hover)",
        "var(--yellow-tournesol-975-75-hover)",
        "var(--border-action-low-green-menthe)",
    ];
    connect() {
        if (this.typeValue === 'bar') {
            this.renderBarChart();
        } else if (this.typeValue === 'multi-column'){
            this.renderMultiSeriesColumnChart(false);  // multi-séries non empilé
        } else if (this.typeValue === 'stacked-column') {
            this.renderMultiSeriesColumnChart(true);   // empilé
        } else if (this.typeValue === 'line') {
            this.renderLineChart();
        } else {
            this.renderPieChart();
        }
    }
    disconnect() {
        if (this.chart) {
            this.chart.destroy();
        }
    }

    renderPieChart(){
        const options = {
            chart: this.getChartPieConfig(),
            exporting: {
                enabled: true
            },
            colors: this.getGradientColors(),
            title: this.getTitleConfig(),
            legend: this.getLegendPieConfig(),
            tooltip: this.getTooltipPieConfig(),
            accessibility: { point: { valueSuffix: '%' } },
            plotOptions: this.getPlotPieOptions(),
            series: [{ data: this.dataValue }]
        };

        this.chart = Highcharts.chart(this.chartTarget, options);
        this.chart.reflow();
    }

    renderBarChart(){
        const sortedData = [...this.dataValue].sort((a, b) => b.y - a.y);
        const options = {
            chart: this.getChartBarConfig(),
            exporting: {
                enabled: true
            },
            colors: this.getGradientColors(),
            xAxis: this.getXAxisBarConfig(),
            yAxis: this.getYAxisBarConfig(),
            title: this.getTitleConfig(),
            legend: {enabled: false},
            tooltip: this.getTooltipBarConfig(),
            accessibility: { point: { valueSuffix: '%' } },
            plotOptions: this.getPlotBarOptions(),
            series: [{
                name: 'Actes',
                data: sortedData
            }],
        };

        this.chart = Highcharts.chart(this.chartTarget, options);
        this.chart.reflow();
    }

    renderMultiSeriesColumnChart(stacked = false) {
        if (!this.datasetValue) return;
        const { categories, series } = this.datasetValue
        console.log(this.datasetValue)

        const highchartsSeries = series.map(s => ({
            name: s.name,
            data: s.y
        }))
        const options = {
            chart: this.getChartColumnConfig(),
            exporting: {
                enabled: true
            },
            colors: this.getGradientColors(),
            xAxis: this.getXAxisColumnConfig(categories),
            yAxis: this.getYAxisBarConfig(),
            title: this.getTitleConfig(),
            legend: {enabled: false},
            tooltip: this.getTooltipColumnConfig(),
            plotOptions: this.getPlotColumnOptions(stacked),
            series: highchartsSeries,
        };

        this.chart = Highcharts.chart(this.chartTarget, options);
        this.chart.reflow();
    }
    renderLineChart() {
        if (!this.hasDatasetValue) return;

        const {categories, series} = this.datasetValue;

        const highchartsSeries = series.map(s => ({
            name: s.name,
            data: s.y,
            type: 'line',
            marker: {enabled: true, radius: 4}
        }));

        const options = {
            chart: this.getChartLineConfig(),
            exporting: {
                enabled: true
            },
            colors: this.getGradientColors(),
            xAxis: this.getXAxisColumnConfig(categories),
            yAxis: this.getYAxisBarConfig(),
            title: this.getTitleConfig(),
            legend: {enabled: false},
            tooltip: this.getTooltipLineConfig(),
            series: highchartsSeries,
        };

        this.chart = Highcharts.chart(this.chartTarget, options);
        this.chart.reflow();
    }

    getChartPieConfig() {
        return {
            height: 600,
            style: { fontFamily: "Marianne" },
            plotBackgroundColor: null,
            plotBorderWidth: null,
            plotShadow: false,
            type: 'pie',
        };
    }

    getChartBarConfig() {
        return {
            type: 'bar',
            height: 600,
            style: { fontFamily: "Marianne" },
            plotBackgroundColor: null,
            plotBorderWidth: null,
            plotShadow: false,
        }
    }

    getChartColumnConfig() {
        return {
            type: 'column',
            height: 600,
            style: { fontFamily: "Marianne" },
            plotBackgroundColor: null,
            plotBorderWidth: null,
            plotShadow: false,
        }
    }

    getChartLineConfig() {
        return {
            type: 'line',
            height: 600,
            style: { fontFamily: "Marianne" },
            plotBackgroundColor: null,
            plotBorderWidth: null,
            plotShadow: false,
        }
    }

    getTitleConfig() {
        return {
            text: this.titleValue,
            style: {
                fontSize: '13px',
                fontWeight: "900",
                color: 'var(--text-title-grey)',
            },
        };
    }

    getGradientColors() {
        return Highcharts.map(this.constructor.CHART_COLORS, color => ({
            radialGradient: { cx: 0.5, cy: 0.3, r: 0.7 },
            stops: [
                [0, color],
                [1, Highcharts.color(color).brighten(-0.3).get('rgb')]
            ]
        }));
    }
    getLegendPieConfig() {
        return {
            itemStyle: {
                color: 'var(--text-title-grey)',
                fontSize: '11px' // Réduire la taille si nécessaire
            },
        };
    }
    getTooltipPieConfig() {
        return {
            borderColor: 'transparent',
            borderRadius: 16,
            backgroundColor: "rgba(245, 245, 245, 1)",
            formatter: function () {
                const percentage = Math.round(this.percentage * 10) / 10;
                return `<b>${this.point.name}: </b>${this.point.y} (${percentage}%)`;
            }
        };
    }
    getTooltipBarConfig() {
        return {
            borderColor: 'transparent',
            borderRadius: 16,
            backgroundColor: "rgba(245, 245, 245, 1)",
            formatter: function () {
                return '<b>' + this.point.name + '</b><br/>' +
                    'Nombre d\'actes: <b>' + this.point.y + '</b>';
            }
        }
    }

    getTooltipColumnConfig() {
        return {
            borderColor: 'transparent',
            borderRadius: 16,
            backgroundColor: "rgba(245, 245, 245, 1)",
            formatter: function () {
                return `<b>${this.x}</b><br/>${this.series.name} : <b>${this.y}</b>`;
            }
        }
    }
    getTooltipLineConfig(){
        return {
            borderColor: 'transparent',
            borderRadius: 16,
            backgroundColor: "rgba(245, 245, 245, 1)",
            formatter() {
                return `<b>${this.x}</b><br/>${this.series.name}: <b>${this.y} jours</b>`;
            }
        }
    }

    getPlotPieOptions() {
        return {
            pie: {
                size: 280,
                innerSize: '0%',
                allowPointSelect: true,
                cursor: 'pointer',
                dataLabels: {
                    enabled: true,
                    format: '<b>{point.y}</b>'
                },
                showInLegend: true,
                //center: ['50%', '40%']
            }
        };
    }

    getPlotBarOptions() {
        return {
            bar: {
                dataLabels: {
                    enabled: true,
                    format: '{point.y}',
                },
            }
        }
    }

    getPlotColumnOptions(stacked) {
        return {
            column: {
                stacking: stacked ? 'normal' : undefined,
                pointPadding: 0.2,
                borderWidth: 0,
                dataLabels: {
                    enabled: true,
                    format: '{y}',
                    style: {
                        fontSize: '11px',
                        fontWeight: 'bold',
                        color: 'var(--text-title-grey)',
                        textOutline: 'none'
                    }
                }
            }
        }
    }

    getXAxisBarConfig(){
        return {
            type: 'category',
            labels: {
                style: {
                    fontSize: '11px',
                    color: 'var(--text-title-grey)',
                }
            }
        }
    }

    getYAxisBarConfig(){
        return {
            title: {
                text: 'Total'
            },
            labels: {
                style: {
                    fontSize: '11px',
                    fontWeight: 'bold',
                    color: 'var(--text-title-grey)',
                }
            }
        }
    }

    getXAxisColumnConfig(categories){
        return {
            categories,
            labels: {
                style: {
                    fontSize: '11px',
                    color: 'var(--text-title-grey)',
                }
            }
        }
    }


}