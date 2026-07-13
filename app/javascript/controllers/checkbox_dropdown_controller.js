import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["menu", "checkbox", "hidden", "label"]

    connect() {
        this.updateLabel()
        document.addEventListener("click", this.closeOnOutsideClick)
    }

    disconnect() {
        document.removeEventListener("click", this.closeOnOutsideClick)
    }

    toggle(event) {
        event.stopPropagation()
        this.menuTarget.classList.toggle("fr-hidden")
    }

    closeOnOutsideClick = (event) => {
        if (!this.element.contains(event.target)) {
            this.menuTarget.classList.add("fr-hidden")
        }
    }

    change() {
        this.updateLabel()
        this.updateHidden()
    }

    updateLabel() {
        const checked = this.checkboxTargets.filter(cb => cb.checked).map(cb => cb.value)
        this.labelTarget.textContent = checked.length > 0 ? checked.join(", ") : this.labelTarget.dataset.placeholder
    }

    updateHidden() {
        const checked = this.checkboxTargets.filter(cb => cb.checked).map(cb => cb.value)
        this.hiddenTarget.value = checked.join(",")
    }
}
