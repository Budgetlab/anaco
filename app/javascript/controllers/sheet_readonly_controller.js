// app/javascript/controllers/sheet_readonly_controller.js
import { Controller } from "@hotwired/stimulus"
import jspreadsheet from "jspreadsheet-ce"
import "jsuites"

export default class extends Controller {
    static values = {
        initial: String,   // données JSON { data: [...] }
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

        this.worksheets = jspreadsheet(this.element, {
            worksheets: [
                {
                    data: initialData,
                    allowInsertColumn: false,
                    allowInsertRow: false,
                    allowDeleteColumn: false,
                    allowDeleteRow: false,
                    allowComments: false,
                    editable: false   // empêche toute édition
                }
            ],
            toolbar: false,
            contextMenu: false
        })

    }

    disconnect() {
        try {
            // Détruit le spreadsheet monté dans ce conteneur DOM
            jspreadsheet.destroy(this.element)
        } catch (e) {
            console.warn("JSS destroy error:", e)
        } finally {
            this.worksheets = null
            this.sheet = null
        }
    }
}
