import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["checkbox", "bulkButton", "selectedCount", "count"]

    connect() {
        this.updateButtonState()
    }

    toggleAll(event) {
        const checked = event.target.checked
        this.checkboxTargets.forEach(cb => cb.checked = checked)
        this.updateButtonState()
    }

    updateButtonState() {
        const selected = this.checkboxTargets.filter(cb => cb.checked).length
        this.bulkButtonTarget.disabled = selected === 0

        // Mettre à jour le nombre sélectionné entre parenthèses
        if (this.hasSelectedCountTarget) {
            this.selectedCountTarget.textContent = `(${selected})`
            this.countTarget.textContent = `(${selected})`
        }
    }

    openModal() {
        const selectedIds = this.checkboxTargets
            .filter(cb => cb.checked)
            .map(cb => cb.value)

        document.getElementById("selected_acte_ids").value = selectedIds
    }

    closeModal(e) {
        e.preventDefault();
    }
}
