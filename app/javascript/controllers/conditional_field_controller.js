import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["checkbox", "field"]
    static values = { inverse: Boolean }

    connect() {
        // Initialize visibility on page load
        this.toggle()
    }

    toggle() {
        // Handle both checkboxes and radio buttons
        let isChecked = false

        if (this.hasCheckboxTarget) {
            // For checkboxes
            if (this.checkboxTarget.type === "checkbox") {
                isChecked = this.checkboxTarget.checked
            }
            // For radio buttons (checked radio = true value)
            else if (this.checkboxTarget.type === "radio") {
                const checkedRadio = this.checkboxTargets.find(radio => radio.checked)
                isChecked = checkedRadio && checkedRadio.value === "true"
            }
        }

        // Inverse logic if specified
        const shouldShow = this.inverseValue ? !isChecked : isChecked

        // Toggle all field targets (support for multiple conditional fields)
        if (this.hasFieldTarget) {
            this.fieldTargets.forEach(field => {
                if (shouldShow) {
                    field.classList.remove("fr-hidden")
                    // Restore required attribute if it was saved
                    const select = field.querySelector("select")
                    if (select && select.dataset.wasRequired === "true") {
                        select.required = true
                    }
                } else {
                    field.classList.add("fr-hidden")
                    // Remove required attribute and save its state
                    const select = field.querySelector("select")
                    if (select) {
                        if (select.required) {
                            select.dataset.wasRequired = "true"
                            select.required = false
                        }
                        // Vider le champ select quand il est caché
                        select.value = ""
                    }
                    // Reset the input field value when hidden
                    const input = field.querySelector("input[type='number']")
                    if (input) {
                        input.value = ""
                    }
                }
            })
        }
    }
}
