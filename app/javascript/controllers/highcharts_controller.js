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

export default class extends Controller {
  static get targets() {
  return ['canvasAvis','canvasNotes1','canvasNotes2','canvasAvisDate','canvasNotesBar',
  ];
  }
  connect() {
    this.syntheseAvis();
    this.showViz();
  }

    showViz(){
      const notes1 = JSON.parse(this.data.get("notes1"));
      const notes2 = JSON.parse(this.data.get("notes2"));
      const avisdate = JSON.parse(this.data.get("avisdate"));
      const notesbar = JSON.parse(this.data.get("notesbar"));
      if (notes1 != null && notes1.length > 0) {
        this.syntheseNote1();
      }
      if (notes2 != null && notes2.length > 0) {
          this.syntheseNote2();
      }
      if (avisdate != null && avisdate.length > 0){
          this.syntheseAvisDate();
      }
      if (notesbar != null && notesbar.length > 0){
          this.syntheseNotesBar();
      }
  }
    syntheseAvis(){
    const data = JSON.parse(this.data.get("avis"));
    const colors = ["var(--background-action-low-green-bourgeon)","var(--artwork-minor-blue-france)", "var(--background-contrast-pink-macaron)","var(--background-disabled-grey)"]
    const options = {
          chart: {
                height:'100%',
                style:{
                    fontFamily: "Marianne",
                },
                plotBackgroundColor: null,
                plotBorderWidth: null,
                plotShadow: false,
                type: 'pie',  
                                  
          },
          exporting:{enabled: false},
          colors: Highcharts.map(colors, function (color) {
              return {
                  radialGradient: {
                      cx: 0.5,
                      cy: 0.3,
                      r: 0.7
                  },
                  stops: [
                      [0, color],
                      [1, Highcharts.color(color).brighten(-0.3).get('rgb')] // darken
                  ]
              };
          }),
          
          title: {
              text: 'Répartition des avis',
             
              style: {
                fontSize: '13px',
                fontWeight: "900",
                color: 'var(--text-title-grey)',
                },
          },
          tooltip: {
              borderColor: 'transparent',
              borderRadius: 16,
              backgroundColor: "rgba(245, 245, 245, 1)",
              formatter: function () {
                return '<b>' + this.point.name +': </b>' + this.point.y + ' (' + Math.round(this.percentage*10)/10 + '% )'
              }
              //pointFormat: '{series.name}: <b>{point.percentage:.1f}%</b>'
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
          series: [{
              name: 'Catégorie',
              data: [
                  { name: 'Avis favorables', y: data[0] },
                  { name: 'Avis favorables avec réserves', y: data[1] },
                  { name: 'Avis défavorables', y: data[2] },
                  { name: 'Avis non renseignés', y: data[3] }
              ]
          }]
    }
    this.chart = new Highcharts.chart(this.canvasAvisTarget, options);
    this.chart.reflow();
  }

    syntheseAvisDate(){
        const data = JSON.parse(this.data.get("avisdate"));
        const colors = ["var(--background-contrast-green-menthe)","var(--background-action-low-blue-france)","var(--background-action-low-green-tilleul-verveine-hover)", "var(--background-action-low-purple-glycine-hover)","var(--background-disabled-grey)"]
        const options = {
            chart: {
                height:'100%',
                style:{
                    fontFamily: "Marianne",
                },
                plotBackgroundColor: null,
                plotBorderWidth: null,
                plotShadow: false,
                type: 'pie',

            },
            exporting:{enabled: false},
            colors: Highcharts.map(colors, function (color) {
                return {
                    radialGradient: {
                        cx: 0.5,
                        cy: 0.3,
                        r: 0.7
                    },
                    stops: [
                        [0, color],
                        [1, Highcharts.color(color).brighten(-0.3).get('rgb')] // darken
                    ]
                };
            }),

            title: {
                text: 'Délais de programmation initiale',

                style: {
                    fontSize: '13px',
                    fontWeight: "900",
                    color: 'var(--text-title-grey)',
                },
            },
            tooltip: {
                borderColor: 'transparent',
                borderRadius: 16,
                backgroundColor: "rgba(245, 245, 245, 1)",
                formatter: function () {
                    return '<b>' + this.point.name +': </b>' + this.point.y + ' (' + Math.round(this.percentage*10)/10 + '% )'
                }
                //pointFormat: '{series.name}: <b>{point.percentage:.1f}%</b>'
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
            series: [{
                name: 'Catégorie',
                data: [
                    { name: 'BOP initiaux reçus avant le 1er mars', y: data[0] },
                    { name: 'BOP initiaux reçus entre le 1er et le 15 mars', y: data[1] },
                    { name: 'BOP initiaux reçus entre le 15 et le 31 mars', y: data[2] },
                    { name: 'BOP initiaux reçus après le 1er avril', y: data[3] },
                    { name: 'BOP initiaux non reçus', y: data[4] },
                ]
            }]
        }
        this.chart = new Highcharts.chart(this.canvasAvisDateTarget, options);
        this.chart.reflow();
    }

    syntheseNotesBar(){
        const data = JSON.parse(this.data.get("notesbar"));
        const colors = ["var(--background-disabled-grey)","var(--background-contrast-pink-macaron)","var(--artwork-minor-blue-france)","var(--background-action-low-green-bourgeon)" ];
        const options = {
            chart: {
                height:'100%',
                style:{
                    fontFamily: "Marianne",
                },
                plotBackgroundColor: null,
                plotBorderWidth: null,
                plotShadow: false,
                type: 'bar',

            },
            colors: colors,
            exporting:{enabled: false},

            title: {
                text: 'Statuts des BOP',

                style: {
                    fontSize: '13px',
                    fontWeight: "900",
                    color: 'var(--text-title-grey)',
                },
            },
            xAxis: {
                categories: ["Début de gestion",'CRG1', 'CRG2'],
            },
            yAxis: {
                min: 0,
                title: {
                    text: '',
                },
                gridLineColor: 'var(--text-inverted-grey)',
            },
            legend: {
                reversed: true
            },
            tooltip: {
                borderColor: 'transparent',
                borderRadius: 16,
                backgroundColor: "rgba(245, 245, 245, 1)",
                formatter: function () {
                    return '<b>' + this.series.name +': </b>' + this.point.y
                }
                //pointFormat: '{series.name}: <b>{point.percentage:.1f}%</b>'
            },
            plotOptions: {
                series: {
                    stacking: 'normal',
                    pointWidth: 15,
                },
            },
            series: [{
                name: 'Notes non reçues',
                data: data[3],
            },{
                name: 'BOP avec besoin de financement',
                data: data[2],
            },{
                name: 'BOP avec consommation à la ressource',
                data: data[1],
            },{
                name: 'BOP avec capacité contributive',
                data: data[0],
            },]
        }
        this.chart = new Highcharts.chart(this.canvasNotesBarTarget, options);
        this.chart.reflow();
    }
    syntheseNote1(){
        const data = JSON.parse(this.data.get("notes1"));
        const colors = ["var(--background-action-low-green-bourgeon)","var(--artwork-minor-blue-france)", "var(--background-contrast-pink-macaron)","var(--background-disabled-grey)"]

        const options = {
            chart: {
                height:'100%',
                style:{
                    fontFamily: "Marianne",
                },
                plotBackgroundColor: null,
                plotBorderWidth: null,
                plotShadow: false,
                type: 'pie',

            },
            exporting:{enabled: false},
            colors: Highcharts.map(colors, function (color) {
                return {
                    radialGradient: {
                        cx: 0.5,
                        cy: 0.3,
                        r: 0.7
                    },
                    stops: [
                        [0, color],
                        [1, Highcharts.color(color).brighten(-0.3).get('rgb')] // darken
                    ]
                };
            }),

            title: {
                text: 'Répartition des notes',

                style: {
                    fontSize: '13px',
                    fontWeight: "900",
                    color: 'var(--text-title-grey)',
                },
            },
            tooltip: {
                borderColor: 'transparent',
                borderRadius: 16,
                backgroundColor: "rgba(245, 245, 245, 1)",
                formatter: function () {
                    return '<b>' + this.point.name +': </b>' + this.point.y + ' (' + Math.round(this.percentage*10)/10 + '% )'
                }
                //pointFormat: '{series.name}: <b>{point.percentage:.1f}%</b>'
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
            series: [{
                name: 'Catégorie',
                data: [
                    { name: 'Aucun risque', y: data[0] },
                    { name: 'Risques éventuels ou modérés', y: data[1] },
                    { name: 'Risques certains ou significatifs', y: data[2] },
                    { name: 'Notes non renseignées', y: data[3] }
                ]
            }]
        }
        this.chart = new Highcharts.chart(this.canvasNotes1Target, options);
        this.chart.reflow();
    }

    syntheseNote2(){
        const data = JSON.parse(this.data.get("notes2"));
        const colors = ["var(--background-action-low-green-bourgeon)","var(--artwork-minor-blue-france)", "var(--background-contrast-pink-macaron)","var(--background-disabled-grey)"]
        const options = {
            chart: {
                height:'100%',
                style:{
                    fontFamily: "Marianne",
                },
                plotBackgroundColor: null,
                plotBorderWidth: null,
                plotShadow: false,
                type: 'pie',

            },
            exporting:{enabled: false},
            colors: Highcharts.map(colors, function (color) {
                return {
                    radialGradient: {
                        cx: 0.5,
                        cy: 0.3,
                        r: 0.7
                    },
                    stops: [
                        [0, color],
                        [1, Highcharts.color(color).brighten(-0.3).get('rgb')] // darken
                    ]
                };
            }),

            title: {
                text: 'Répartition des notes',

                style: {
                    fontSize: '13px',
                    fontWeight: "900",
                    color: 'var(--text-title-grey)',
                },
            },
            tooltip: {
                borderColor: 'transparent',
                borderRadius: 16,
                backgroundColor: "rgba(245, 245, 245, 1)",
                formatter: function () {
                    return '<b>' + this.point.name +': </b>' + this.point.y + ' (' + Math.round(this.percentage*10)/10 + '% )'
                }
                //pointFormat: '{series.name}: <b>{point.percentage:.1f}%</b>'
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
            series: [{
                name: 'Catégorie',
                data: [
                    { name: 'Aucun risque', y: data[0] },
                    { name: 'Risques éventuels ou modérés', y: data[1] },
                    { name: 'Risques certains ou significatifs', y: data[2] },
                    { name: 'Notes non renseignées', y: data[3] }
                ]
            }]
        }
        this.chart = new Highcharts.chart(this.canvasNotes2Target, options);
        this.chart.reflow();
    }

}
