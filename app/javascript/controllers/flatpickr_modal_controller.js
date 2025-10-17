import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import "flatpickr/dist/l10n/fr.js"

export default class extends Controller {
    connect() {
        if (this.fp) this.fp.destroy()

        this.fp = flatpickr(this.element, {
            locale: 'fr',
            dateFormat: "d/m/Y",
            defaultDate: this.element.value || null,
            allowInput: true,
            appendTo: document.querySelector(this.element.dataset.flatpickrModalAppendTo) || undefined
        })
    }

    disconnect() {
        if (this.fp) this.fp.destroy()
    }
}
