import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["checkbox", "field"]

    connect() {
        // Initialize visibility on page load
        this.toggle()
    }

    toggle() {
        const isChecked = this.checkboxTarget.checked
        if (isChecked) {
            this.fieldTarget.classList.remove("fr-hidden")
        } else {
            this.fieldTarget.classList.add("fr-hidden")
            // Reset the input field value when unchecked
            const input = this.fieldTarget.querySelector("input[type='number']")
            if (input) {
                input.value = ""
            }
        }
    }
}
