import {Controller} from "@hotwired/stimulus"
import Highcharts from "highcharts"
import exporting from "exporting"
import accessibility from "accessibility"
import nodata from "nodata"

exporting(Highcharts)
accessibility(Highcharts)
nodata(Highcharts)

export default class extends Controller {
    static get targets() {
        return ['canvasAvis', 'canvasNotes1', 'canvasNotes2', 'canvasAvisDate', 'canvasNotesBar'];
    }

    connect() {
        if (this.hasCanvasAvisTarget) {
            this.syntheseChart('avis')
        }
        this.showViz();
    }

    showViz() {
        const notes1 = JSON.parse(this.data.get("notes1"));
        const notes2 = JSON.parse(this.data.get("notes2"));
        const avisdate = JSON.parse(this.data.get("avisdate"));
        const notesbar = JSON.parse(this.data.get("notesbar"));
        if (notes1 != null && notes1.length > 0 && this.hasCanvasNotes1Target) {
            this.syntheseChart('notes1')
        }
        if (notes2 != null && notes2.length > 0 && this.hasCanvasNotes2Target) {
            this.syntheseChart('notes2')
        }
        if (avisdate != null && avisdate.length > 0 && this.hasCanvasAvisDateTarget) {
            const colors = ["var(--background-contrast-green-menthe)", "var(--background-contrast-blue-cumulus-active)", "var(--background-action-low-green-tilleul-verveine-hover)", "var(--background-action-high-purple-glycine-active)", "var(--background-contrast-brown-caramel)", "var(--background-disabled-grey)"]
            const title = 'Calendrier de réception des programmations initiales';
            const target = this.canvasAvisDateTarget;
            const data = JSON.parse(this.data.get("avisdate"));
            const series = [{
                name: 'Catégorie',
                data: [
                    {name: 'BOP initiaux reçus avant le 1er mars', y: data[0]},
                    {name: 'BOP initiaux reçus entre le 1er et le 15 mars', y: data[1]},
                    {name: 'BOP initiaux reçus entre le 15 et le 31 mars', y: data[2]},
                    {name: 'BOP initiaux reçus après le 1er avril', y: data[3]},
                    {name: 'Non reçu', y: data[4]},
                    {name: 'Non renseigné', y: data[5]},
                ]
            }]
            this.synthesePie(colors, title, series, target);
        }
        if (notesbar != null && notesbar.categories && notesbar.categories.length > 0 && this.hasCanvasNotesBarTarget) {
            this.syntheseNotesBar();
        }
    }

    synthesePie(colors, title, series, target) {
        const options = {
            chart: {
                height: 500,
                style: {
                    fontFamily: "Marianne",
                },
                plotBackgroundColor: null,
                plotBorderWidth: null,
                plotShadow: false,
                type: 'pie',
            },
            exporting: {enabled: false},
            colors: Highcharts.map(colors, function (color) {
                return {
                    radialGradient: {
                        cx: 0.5,
                        cy: 0.3,
                        r: 0.7
                    },
                    stops: [
                        [0, color],
                        [1, Highcharts.color(color).brighten(-0.3).get('rgb')]
                    ]
                };
            }),
            title: {
                text: title,
                style: {
                    fontSize: '18px',
                    fontWeight: "900",
                    color: 'var(--text-title-grey)',
                },
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
                    return '<b>' + this.point.name + ': </b>' + this.point.y + ' (' + Math.round(this.percentage * 10) / 10 + '% )'
                }
            },
            accessibility: {
                point: {
                    valueSuffix: '%'
                }
            },
            plotOptions: {
                pie: {
                    size: '100%',
                    innerSize: '0%',
                    allowPointSelect: true,
                    cursor: 'pointer',
                    dataLabels: {
                        enabled: false
                    },
                    showInLegend: true,
                }
            },
            series: series
        }
        this.chart = Highcharts.chart(target, options);
        this.chart.reflow();
    }

    syntheseNotesBar() {
        const payload = JSON.parse(this.data.get("notesbar"));
        const categories = payload.categories;
        const [capacite, consommation, besoin, nonRecu, nonRenseigne] = payload.series;
        const colors = [
            "var(--background-disabled-grey)",
            "var(--background-contrast-brown-caramel)",
            "var(--background-action-high-red-marianne-active)",
            "var(--artwork-minor-blue-france)",
            "var(--background-action-low-green-bourgeon)"
        ];
        const options = {
            chart: {
                height: 500,
                style: {
                    fontFamily: "Marianne",
                },
                plotBackgroundColor: null,
                plotBorderWidth: null,
                plotShadow: false,
                type: 'bar',
            },
            colors: colors,
            exporting: {enabled: false},
            title: {
                text: 'Indicateurs de soutenabilité des BOP',
                style: {
                    fontSize: '18px',
                    fontWeight: "900",
                    color: 'var(--text-title-grey)',
                },
            },
            xAxis: {
                categories: categories,
                labels: {
                    style: {
                        color: 'var(--text-title-grey)',
                    },
                },
            },
            yAxis: {
                min: 0,
                title: {
                    text: '',
                },
                gridLineColor: 'var(--text-inverted-grey)',
            },
            legend: {
                reversed: true,
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
                    return '<b>' + this.series.name + ': </b>' + this.point.y
                }
            },
            plotOptions: {
                series: {
                    stacking: 'normal',
                    pointWidth: 15,
                },
            },
            series: [{
                name: 'Non renseigné',
                data: nonRenseigne,
            }, {
                name: 'Non reçu',
                data: nonRecu,
            }, {
                name: 'BOP avec besoin de financement',
                data: besoin,
            }, {
                name: 'BOP avec consommation à la ressource',
                data: consommation,
            }, {
                name: 'BOP avec capacité contributive',
                data: capacite,
            }]
        }
        this.chart = Highcharts.chart(this.canvasNotesBarTarget, options);
        this.chart.reflow();
    }

    syntheseChart(type) {
        const colors = [
            "var(--background-action-low-green-bourgeon)",
            "var(--background-alt-green-menthe-active)",
            "var(--background-action-high-red-marianne-active)",
            "var(--background-disabled-grey)",
            "var(--border-action-low-beige-gris-galet)"
        ];
        const chartConfig = {
            'avis': {
                dataKey: 'avis',
                title: 'Répartition des avis DPG/DPU',
                target: 'canvasAvisTarget',
                labels: [
                    'Avis favorables',
                    'Avis favorables avec réserves',
                    'Avis défavorables',
                    'Avis non renseignés'
                ],
            },
            'notes1': {
                dataKey: 'notes1',
                title: 'Répartition des notes CRG1',
                target: 'canvasNotes1Target',
                labels: [
                    'Aucun risque',
                    'Risques éventuels ou modérés',
                    'Risques certains ou significatifs',
                    'Notes non renseignées'
                ],
            },
            'notes2': {
                dataKey: 'notes2',
                title: 'Répartition des notes CRG2',
                target: 'canvasNotes2Target',
                labels: [
                    'Aucun risque',
                    'Risques modérés',
                    'Risques significatifs',
                    'Notes non renseignées'
                ],
            },
        };

        const config = chartConfig[type];
        if (!config) return;

        const data = JSON.parse(this.data.get(config.dataKey));
        const series = [{
            name: 'Catégorie',
            data: data.map((value, index) => ({
                name: config.labels[index],
                y: value
            }))
        }];

        const options = {
            chart: {
                height: '100%',
                style: {
                    fontFamily: "Marianne",
                },
                plotBackgroundColor: null,
                plotBorderWidth: null,
                plotShadow: false,
                type: 'pie',
            },
            exporting: {enabled: false},
            colors: Highcharts.map(colors, color => ({
                radialGradient: {
                    cx: 0.5,
                    cy: 0.3,
                    r: 0.7
                },
                stops: [
                    [0, color],
                    [1, Highcharts.color(color).brighten(-0.3).get('rgb')]
                ]
            })),
            title: {
                text: config.title,
                style: {
                    fontSize: '13px',
                    fontWeight: "900",
                    color: 'var(--text-title-grey)',
                },
            },
            legend: {
                itemStyle: {
                    color: 'var(--text-title-grey)',
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
            accessibility: {
                point: {
                    valueSuffix: '%'
                }
            },
            plotOptions: {
                pie: {
                    size: '100%',
                    innerSize: '80%',
                    allowPointSelect: true,
                    cursor: 'pointer',
                    dataLabels: {
                        enabled: false
                    },
                    showInLegend: true,
                }
            },
            series: series
        };

        this.chart = Highcharts.chart(this[config.target], options);
        this.chart.reflow();
    }
}
