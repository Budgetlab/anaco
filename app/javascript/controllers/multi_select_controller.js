import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="type-observations"
export default class extends Controller {
    static targets = ["select", "container", "hidden"]

    connect() {
        this.updateHiddenField()
    }

    add(event) {
        const selectedValue = this.selectTarget.value
        if (!selectedValue || this.hasTag(selectedValue)) return

        const li = document.createElement("li")
        li.dataset.action = "click->multi-select#remove"
        li.dataset.value = selectedValue

        const button = document.createElement("button")
        button.className = "fr-tag fr-tag--dismiss"
        //tag.type = "button"
        //tag.dataset.value = selectedValue
        //tag.setAttribute("data-action", "click->multi-select#remove")
        button.setAttribute("aria-label", `Retirer ${selectedValue}`)
        button.innerHTML = `${selectedValue}`

        li.appendChild(button)
        this.containerTarget.appendChild(li)
        this.updateHiddenField()

        // Réinitialiser le select après sélection
        this.selectTarget.value = ""
    }

    remove(event) {
        event.currentTarget.closest("li").remove()
        this.updateHiddenField()
    }

    updateHiddenField() {
        const tags = Array.from(this.containerTarget.querySelectorAll("li")).map(li => li.dataset.value)
        this.hiddenTarget.value = tags.join(",")
    }

    hasTag(value) {
        return Array.from(this.containerTarget.querySelectorAll("li")).some(li => li.dataset.value === value)
    }
}
