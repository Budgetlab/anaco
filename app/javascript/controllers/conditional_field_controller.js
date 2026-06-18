import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["checkbox", "field"]
    static values = { inverse: Boolean }

    connect() {
        // Initial visibility est rendue côté serveur (classes ERB fr-hidden).
        // Mais l'attribut HTML required est aussi rendu côté serveur, indépendamment.
        // On synchronise ici : retire required sur les champs initialement masqués
        // pour ne pas bloquer la validation HTML5 native (requestSubmit).
        if (this.hasFieldTarget) {
            this.fieldTargets.forEach(field => {
                if (field.classList.contains("fr-hidden")) {
                    field.querySelectorAll("select, input, textarea").forEach(el => {
                        if (el.required) {
                            el.dataset.wasRequired = "true"
                            el.required = false
                        }
                    })
                }
            })
        }
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

        // Toggle all field targets (support for multiple conditional fields)
        // Per-field opt-in via `data-inverse="true"` ; sinon, fallback sur l'inverseValue racine.
        if (this.hasFieldTarget) {
            this.fieldTargets.forEach(field => {
                const fieldInverse = field.dataset.inverse === "true" ? true : this.inverseValue
                const shouldShow = fieldInverse ? !isChecked : isChecked
                // Tous les inputs (select, input, textarea) participent au toggle required.
                const inputs = field.querySelectorAll("select, input, textarea")
                if (shouldShow) {
                    field.classList.remove("fr-hidden")
                    inputs.forEach(el => {
                        if (el.dataset.wasRequired === "true") {
                            el.required = true
                        }
                    })
                } else {
                    field.classList.add("fr-hidden")
                    inputs.forEach(el => {
                        if (el.required) {
                            el.dataset.wasRequired = "true"
                            el.required = false
                        }
                    })
                    // Vider les selects et number inputs masqués (préserve les text inputs).
                    field.querySelectorAll("select").forEach(el => { el.value = "" })
                    field.querySelectorAll("input[type='number']").forEach(el => { el.value = "" })
                }
            })
        }
    }
}
