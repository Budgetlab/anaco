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

    })
  }

  disconnect() {
    if (this.fp) this.fp.destroy()
  }
}
