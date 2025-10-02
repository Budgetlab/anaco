// app/javascript/controllers/tag_select_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["checkbox"]

    connect() {
        this.update() // initialise l'état à l'ouverture
    }

    toggle() {
        this.update()
    }

    update() {
        this.element.classList.toggle("is-selected", this.checkboxTarget.checked)
    }
}
