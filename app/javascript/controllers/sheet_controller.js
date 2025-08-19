// app/javascript/controllers/sheet_controller.js
import { Controller } from "@hotwired/stimulus"
import jspreadsheet from "jspreadsheet-ce"
import "jsuites"

// Stimulus controller pour un mini-tableur (jspreadsheet v5)
export default class extends Controller {
    static values = {
        inputId: String,   // id du hidden_field
        initial: String,   // données JSON initiales { data: [...] }
        minCols: Number,
        minRows: Number
    }

    connect() {
        let parsed = JSON.parse(this.initialValue)

// Si jamais c’est encore une string (double encodage), on re-parse
        if (typeof parsed === "string") {
            parsed = JSON.parse(parsed)
        }
        const initialData = parsed.data || [[]]

        // Initialisation jspreadsheet v5
        this.worksheets = jspreadsheet(this.element, {
            // toolbar: true, ajouter link google font material icon pour le style
            worksheets: [
                {
                    data: initialData,
                    minDimensions: [
                        this.minColsValue || 6,
                        this.minRowsValue || 10
                    ],
                    allowInsertColumn: true,
                    allowInsertRow: true,
                    allowDeleteColumn: true,
                    allowDeleteRow: true,
                    allowComments: false,
                }
            ],
            onchange: (worksheetInstance) => {
                this.sync(worksheetInstance)
            }
        })

        this.sheet = this.worksheets[0] // première feuille
        this.sync(this.sheet) // synchro initiale
    }

    sync(worksheet) {
        const input = document.getElementById(this.inputIdValue)
        if (!input) return
        const data = worksheet.getData()
        input.value = JSON.stringify({ data })
    }

    disconnect() {
        if (this.worksheets) {
            this.worksheets.forEach(ws => ws.destroy())
        }
    }
}
