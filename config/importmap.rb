# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/custom", under: "custom"
pin "stimulus-flatpickr", to: "https://ga.jspm.io/npm:stimulus-flatpickr@3.0.0-0/dist/index.m.js"
pin "flatpickr" # @4.6.13
pin "flatpickr/dist/l10n/fr.js", to: "flatpickr--dist--l10n--fr.js.js" # @4.6.13
pin "highcharts", to: "https://ga.jspm.io/npm:highcharts@11.4.1/highcharts.js" # @11.4.1
pin "highcharts-more", to: "https://ga.jspm.io/npm:highcharts@11.4.1/highcharts-more.js"
pin "exporting", to: "https://ga.jspm.io/npm:highcharts@11.4.1/modules/exporting.js"
pin "accessibility", to: "https://ga.jspm.io/npm:highcharts@11.4.1/modules/accessibility.js"
pin "data", to: "https://ga.jspm.io/npm:highcharts@11.4.1/modules/export-data.js"
pin "nodata", to: "https://ga.jspm.io/npm:highcharts@11.4.1/modules/no-data-to-display.js"