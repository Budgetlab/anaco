import { Controller } from "@hotwired/stimulus"
import flatpickr from "flatpickr"
import "flatpickr/dist/l10n/fr.js"
// create a new Stimulus controller by extending stimulus-flatpickr wrapper controller
export default class extends Controller {
  connect() {
    flatpickr(this.element, {
      locale: 'fr',
      dateFormat: "d/m/Y",
    })
  }
}