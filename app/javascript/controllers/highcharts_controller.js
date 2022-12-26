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
  return ['canvasAvis','canvasNotes1','canvasNotes2',
  ];
  }
  connect() {
    this.syntheseAvis();
    this.showViz();
  }

  showViz(){
      const notes1 = JSON.parse(this.data.get("notes1"));
      const notes2 = JSON.parse(this.data.get("notes2"));
      if (notes1.length > 0) {
        this.syntheseNote1();
      }
      if (notes2.length > 0) {
          this.syntheseNote2();
      }
  }
    syntheseAvis(){
    const data = JSON.parse(this.data.get("avis"));
    const colors = ["var(--background-action-low-green-bourgeon)","var(--artwork-minor-blue-france)","var(--artwork-minor-pink-macaron)", "var(--background-contrast-pink-macaron)"]
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

    syntheseNote1(){
        const data = JSON.parse(this.data.get("notes1"));
        const colors = ["var(--background-action-low-green-bourgeon)","var(--artwork-minor-blue-france)","var(--artwork-minor-pink-macaron)", "var(--background-contrast-pink-macaron)"]
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
                    { name: 'BOP avec capacité contributive', y: data[0] },
                    { name: 'BOP avec consommation à la ressource', y: data[1] },
                    { name: 'BOP avec besoin de financement', y: data[2] },
                    { name: 'Notes non renseignés', y: data[3] }
                ]
            }]
        }
        this.chart = new Highcharts.chart(this.canvasNotes1Target, options);
        this.chart.reflow();
    }

    syntheseNote2(){
        const data = JSON.parse(this.data.get("notes2"));
        const colors = ["var(--background-action-low-green-bourgeon)","var(--artwork-minor-blue-france)","var(--artwork-minor-pink-macaron)", "var(--background-contrast-pink-macaron)"]
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
                    { name: 'BOP avec capacité contributive', y: data[0] },
                    { name: 'BOP avec consommation à la ressource', y: data[1] },
                    { name: 'BOP avec besoin de financement', y: data[2] },
                    { name: 'Notes non renseignés', y: data[3] }
                ]
            }]
        }
        this.chart = new Highcharts.chart(this.canvasNotes2Target, options);
        this.chart.reflow();
    }

}
