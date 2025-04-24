import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import "flatpickr/dist/l10n/fr.js"

export default class extends Controller {
  connect() {
    if (this.fp) this.fp.destroy()

    // Trouve un conteneur parent du champ, typiquement la modal
    const modalContainer = this.element.closest('.fr-modal') || document.body

    this.fp = flatpickr(this.element, {
      locale: 'fr',
      dateFormat: "d/m/Y",
      defaultDate: this.element.value || null,
      appendTo: modalContainer // 👈 très important ici
    })
  }

  disconnect() {
    if (this.fp) this.fp.destroy()
  }
}
