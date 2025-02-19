# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
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
pin "@stimulus-components/rails-nested-form", to: "@stimulus-components--rails-nested-form.js" # @5.0.0
pin "jspdf" # @2.5.2
pin "@babel/runtime/helpers/asyncToGenerator", to: "@babel--runtime--helpers--asyncToGenerator.js" # @7.26.0
pin "@babel/runtime/helpers/defineProperty", to: "@babel--runtime--helpers--defineProperty.js" # @7.26.0
pin "@babel/runtime/helpers/typeof", to: "@babel--runtime--helpers--typeof.js" # @7.26.0
pin "canvg" # @4.0.2
pin "html2canvas", to: "https://ga.jspm.io/npm:html2canvas@1.4.1/dist/html2canvas.js"
pin "fflate" # @0.8.2
pin "performance-now" # @2.1.0
pin "process" # @2.1.0
pin "raf" # @3.4.1
pin "rgbcolor" # @1.0.1
pin "stackblur-canvas" # @2.7.0
pin "svg-pathdata" # @6.0.3
pin "trix"
pin "@rails/actiontext", to: "actiontext.esm.js"
