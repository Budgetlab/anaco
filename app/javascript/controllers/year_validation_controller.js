// app/javascript/controllers/year_validator_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input", "error"]

    connect() {
    }

    validateYear() {
        const value = parseInt(this.inputTarget.value)
        // Limiter à 4 chiffres
        if (this.inputTarget.value.length > 4) {
            this.inputTarget.value = this.inputTarget.value.slice(0, 4);
        }
        //if (isNaN(value) || value < 2000 || value > 2100) {
        //    this.inputTarget.setCustomValidity('L\'année doit être comprise entre 2000 et 2100')
        //    this.errorTarget.style.display = 'block'
        //} else {
        //    this.inputTarget.setCustomValidity('')
        //    this.errorTarget.style.display = 'none'
        //}
    }
}