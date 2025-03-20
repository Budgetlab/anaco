import { Controller } from "@hotwired/stimulus"
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
  static get targets() {
  return ['canvasAvis','canvasNotes1','canvasNotes2','canvasAvisDate','canvasNotesBar','canvasActeAvis', 'canvasActeVisa', 'canvasActeSuspension', 'canvasActeInstructeur', 'canvasActesMensuel'
  ];
  }
  connect() {
      if (this.hasCanvasAvisTarget) {
          this.syntheseChart('avis')
      }
      this.showViz();

      if (this.hasCanvasActeAvisTarget){
          this.syntheseChart('actesAvis')
      }
      if (this.hasCanvasActeVisaTarget){
          this.syntheseChart('actesVisa')
      }
      if (this.hasCanvasActeSuspensionTarget){
          const colors = ["var(--background-disabled-grey)","var(--background-action-high-red-marianne-active)","var(--artwork-minor-blue-france)","var(--background-action-low-green-bourgeon)" ];
          const title = 'Typologie des actes suspendus/interrompus'
          const target = this.canvasActeSuspensionTarget;
          // Récupérer et parser les données JSON
          const suspensionsData = JSON.parse(this.canvasActeSuspensionTarget.dataset.acteSuspensions);
          // Transformer les données en catégories et séries
          const { categories, series } = this.formatSuspensionsData(suspensionsData);
          this.syntheseCol(colors, title, categories, series, target)

      }
      if (this.hasCanvasActeInstructeurTarget){
          const title = "Nombre d'actes traités par instructeur"
          const target = this.canvasActeInstructeurTarget;
          // Récupérer et parser les données JSON
          const instructeursData = JSON.parse(this.canvasActeInstructeurTarget.dataset.acteInstructeur);
          const series  = this.formatDataForPackedBubble(instructeursData)
          this.syntheseBubble(title, series, target)
      }

      if (this.hasCanvasActesMensuelTarget) {
          const title = "Évolution mensuelle des actes"
          const title_y = 'Nombre d\'actes'
          const target = this.canvasActesMensuelTarget;

          // Récupérer et parser les données JSON
          const monthlyData = JSON.parse(this.canvasActesMensuelTarget.dataset.actesMensuel);

          // Transformer les données pour le graphique
          const { categories, series } = this.formatMonthlyData(monthlyData);

          // Générer le graphique
          this.syntheseColumn(title,title_y, categories, series, target);
      }

  }

    showViz(){
      const notes1 = JSON.parse(this.data.get("notes1"));
      const notes2 = JSON.parse(this.data.get("notes2"));
      const avisdate = JSON.parse(this.data.get("avisdate"));
      const notesbar = JSON.parse(this.data.get("notesbar"));
      if (notes1 != null && notes1.length > 0) {
          this.syntheseChart('notes1')
      }
      if (notes2 != null && notes2.length > 0) {
          this.syntheseChart('notes2')
      }
      if (avisdate != null && avisdate.length > 0){
          this.syntheseAvisDate();
      }
      if (notesbar != null && notesbar.length > 0){
          this.syntheseNotesBar();
      }
  }

    syntheseAvisDate(){
        const data = JSON.parse(this.data.get("avisdate"));
        const colors = ["var(--background-contrast-green-menthe)","var(--background-contrast-blue-cumulus-active)","var(--background-action-low-green-tilleul-verveine-hover)", "var(--background-action-high-purple-glycine-active)","var(--background-disabled-grey)"]
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
            legend:{
                itemStyle: {
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
        this.chart = Highcharts.chart(this.canvasAvisDateTarget, options);
        this.chart.reflow();
    }

    syntheseNotesBar(){
        const data = JSON.parse(this.data.get("notesbar"));
        const colors = ["var(--background-disabled-grey)","var(--background-action-high-red-marianne-active)","var(--artwork-minor-blue-france)","var(--background-action-low-green-bourgeon)" ];
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
                itemStyle: {
                    color: 'var(--text-title-grey)',
                },
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
        this.chart = Highcharts.chart(this.canvasNotesBarTarget, options);
        this.chart.reflow();
    }

    syntheseChart(type) {
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
            'actesAvis': {
                dataKey: 'actesAvis',
                title: 'Avis HT2 clôturés',
                target: 'canvasActeAvisTarget',
                labels: [
                    'Favorable',
                    'Favorable avec observations',
                    'Défavorable',
                    'Saisine a posteriori',
                    'Retour sans décision (sans suite)'
                ]
            },
            'actesVisa': {
                dataKey: 'actesVisa',
                title: 'Visas HT2 clôturés',
                target: 'canvasActeVisaTarget',
                labels: [
                    'Visa accordé',
                    'Visa accordé avec observations',
                    'Refus de visa',
                    'Saisine a posteriori',
                    'Retour sans décision (sans suite)'
                ]
            }
        };

        const config = chartConfig[type];
        if (!config) return;

        const data = JSON.parse(this.data.get(config.dataKey)) || this.prepareOrderedData(type);
        const colors = [
            "var(--background-action-low-green-bourgeon)",
            "var(--artwork-minor-blue-france)",
            "var(--background-action-high-red-marianne-active)",
            "var(--background-disabled-grey)",
            "var(--background-action-high-beige-gris-galet)"
        ];

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
            exporting: {
                enabled: false
            },
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
                formatter: function() {
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
            series: [{
                name: 'Catégorie',
                data: data.map((value, index) => ({
                    name: config.labels[index],
                    y: value
                }))
            }]
        };

        this.chart = Highcharts.chart(this[config.target], options);
        this.chart.reflow();
    }


    // Cette nouvelle méthode préparera les données pour le graphique
    prepareOrderedData(type) {
        const chartConfig = {
            'actesAvis': {
                dataKey: 'acteAvis',
                data: this.canvasActeAvisTarget.dataset.acteAvis,
                labels: [
                    'Favorable',
                    'Favorable avec observations',
                    'Défavorable',
                    'Saisine a posteriori',
                    'Retour sans décision (sans suite)'
                ]
            },
            'actesVisa': {
                dataKey: 'actesVisa',
                data: this.canvasActeVisaTarget.dataset.acteVisa,
                labels: [
                    'Visa accordé',
                    'Visa accordé avec observations',
                    'Refus de visa',
                    'Saisine a posteriori',
                    'Retour sans décision (sans suite)'
                ]
            }

        };

        const config = chartConfig[type];
        if (!config) return [];

        // Récupérer les données brutes depuis le dataset
        const rawData = JSON.parse(config.data);


        // Créer un tableau ordonné avec des valeurs par défaut à 0
        const orderedData = Array(config.labels.length).fill(0);

        // Remplir le tableau avec les valeurs existantes
        Object.entries(rawData).forEach(([decision, count]) => {
            const decisionName = decision && decision !== "null" ? decision : "Non spécifié";

            // Trouver l'index dans notre liste ordonnée
            const index = config.labels.findIndex(label =>
                label.toLowerCase() === decisionName.toLowerCase()
            );

            // Si trouvé, mettre à jour la valeur
            if (index !== -1) {
                orderedData[index] = count;
            } else {
                // Si c'est une décision qui n'est pas dans notre liste, on peut l'ajouter à la fin
                // ou l'ignorer selon votre besoin
                console.log(`Décision non répertoriée: ${decisionName}`);
            }
        });

        return orderedData;
    }


    syntheseCol(colors, title, categories, series, target){
        const options = {
            chart: {

                style:{
                    fontFamily: "Marianne",
                },
                plotBackgroundColor: null,
                plotBorderWidth: null,
                plotShadow: false,
                type: 'column',

            },
            colors: colors,
            exporting:{enabled: false},

            title: {
                text: title,

                style: {
                    fontSize: '13px',
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
                itemStyle: {
                    color: 'var(--text-title-grey)',
                },
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
                    pointWidth: 40,
                },
            },
            series: series
        }
        this.chart = Highcharts.chart(target, options);
        this.chart.reflow();
    }

    formatSuspensionsData(data) {
        // Extraire les catégories (types d'actes)
        const categories = data.map(item => item.type_acte);

        // Obtenir tous les motifs uniques
        const allMotifs = [];
        data.forEach(item => {
            item.motifs.forEach(motifObj => {
                if (!allMotifs.includes(motifObj.motif)) {
                    allMotifs.push(motifObj.motif);
                }
            });
        });

        // Créer les séries pour chaque motif
        const series = allMotifs.map(motif => {
            return {
                name: motif,
                data: data.map(item => {
                    // Trouver le motif dans les données de ce type d'acte, ou retourner 0
                    const motifData = item.motifs.find(m => m.motif === motif);
                    return motifData ? motifData.count : 0;
                })
            };
        });

        return { categories, series };
    }

    syntheseBubble(title, series, target){
        const options = {
            chart: {
                type: 'packedbubble',
                height: '100%',
                style: {
                    fontFamily: "Marianne",
                },
            },
            exporting:{enabled: false},
            colors: ["var(--artwork-minor-blue-france)"],
            title: {
                text: title,
                style: {
                    fontSize: '13px',
                    fontWeight: "900",
                    color: 'var(--text-title-grey)',
                },
            },
            plotOptions: {
                packedbubble: {
                    minSize: '30%',
                    maxSize: '120%',
                    zMin: 0,
                    layoutAlgorithm: {
                        gravitationalConstant: 0.02,
                        splitSeries: false,
                        seriesInteraction: true,
                        dragBetweenSeries: true,
                        parentNodeLimit: true
                    },
                    dataLabels: {
                        enabled: true,
                        format: '{point.name}',
                        style: {
                            color: 'var(--text-title-grey)',
                            textOutline: 'none',
                            fontWeight: 'normal'
                        }
                    }
                }
            },
            tooltip: {
                useHTML: true,
                pointFormat: '<b>{point.name}:</b> {point.value}'
            },
            series: series,
            // Désactiver la légende car nous avons déjà des étiquettes dans les bulles
            legend: {
                enabled: false
            }
        };
        this.chart = Highcharts.chart(target, options);
        this.chart.reflow();
    }

    formatDataForPackedBubble(data) {
        // Convertir le hash en tableau d'objets
        const dataArray = Object.entries(data).map(([instructeur, count]) => ({
            name: instructeur || "Non assigné",
            value: count
        })).sort((a, b) => b.value - a.value);

        // Créer la structure series avec les données formatées
        const series = [{
            name: "Actes traités",
            data: dataArray
        }];

        return series;
    }

    syntheseColumn(title, title_y, categories, series, target) {
        const options = {
            chart: {
                type: 'column',
                style: {
                    fontFamily: "Marianne",
                }
            },
            exporting:{enabled: false},
            colors: ["var(--border-action-low-green-menthe)","var(--background-action-high-success-hover)"],
            title: {
                text: title,
                style: {
                    fontSize: '13px',
                    fontWeight: "900",
                    color: 'var(--text-title-grey)',
                }
            },
            xAxis: {
                categories: categories,
                crosshair: true,
                labels: {
                    style: {
                        color: 'var(--text-title-grey)',
                    }
                }
            },
            yAxis: {
                min: 0,
                title: {
                    text: title_y,
                },
                gridLineColor: 'var(--text-inverted-grey)',
            },
            tooltip: {
                headerFormat: '<span style="font-size:10px">{point.key}</span><table>',
                pointFormat: '<tr><td style="padding:0">{series.name}: </td>' +
                    '<td style="padding:0"><b>{point.y}</b></td></tr>',
                footerFormat: '</table>',
                shared: true,
                useHTML: true
            },
            plotOptions: {
                column: {
                    pointPadding: 0.2,
                    borderWidth: 0,
                    dataLabels: {
                        enabled: true,
                        format: '{point.y}'
                    }
                }
            },
            series: series
        };

        this.chart = Highcharts.chart(target, options);
        this.chart.reflow();
    }


    formatMonthlyData(data) {
        // Extraire les noms des mois pour les catégories
        const categories = data.map(item => item.mois);

        // Créer les séries pour les actes créés et clôturés
        const series = [
            {
                name: 'Actes créés',
                data: data.map(item => item.actes_crees),
            },
            {
                name: 'Actes clôturés',
                data: data.map(item => item.actes_clotures),
            }
        ];

        return { categories, series };
    }
}
