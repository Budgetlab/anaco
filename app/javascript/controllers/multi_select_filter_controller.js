import { Controller } from "@hotwired/stimulus"

// Contrôleur pour le multi-select dans les filtres de recherche
export default class extends Controller {
    static targets = ["select", "container", "hiddenContainer"]
    static values = { paramName: String }

    connect() {
        // Charger les valeurs existantes depuis les champs cachés au démarrage
        this.loadExistingValues()
    }

    loadExistingValues() {
        // Récupérer tous les champs cachés existants
        const existingInputs = this.hiddenContainerTarget.querySelectorAll('input[type="hidden"]')
        existingInputs.forEach(input => {
            const value = input.value
            if (value && !this.hasTag(value)) {
                this.createTag(value)
            }
        })
    }

    add(event) {
        const selectedValue = this.selectTarget.value
        if (!selectedValue || this.hasTag(selectedValue)) return

        this.createTag(selectedValue)
        this.updateHiddenFields()

        // Réinitialiser le select après sélection
        this.selectTarget.value = ""
    }

    createTag(value) {
        const li = document.createElement("li")
        li.dataset.action = "click->multi-select-filter#remove"
        li.dataset.value = value

        const button = document.createElement("button")
        button.className = "fr-tag fr-tag--dismiss"
        button.type = "button"
        button.setAttribute("aria-label", `Retirer ${value}`)
        button.innerHTML = `${value}`

        li.appendChild(button)
        this.containerTarget.appendChild(li)
    }

    remove(event) {
        event.preventDefault()
        event.currentTarget.closest("li").remove()
        this.updateHiddenFields()
    }

    updateHiddenFields() {
        // Vider tous les champs cachés existants
        this.hiddenContainerTarget.innerHTML = ""

        // Créer un champ caché pour chaque tag
        const tags = Array.from(this.containerTarget.querySelectorAll("li"))
        tags.forEach(li => {
            const input = document.createElement("input")
            input.type = "hidden"
            input.name = this.paramNameValue
            input.value = li.dataset.value
            this.hiddenContainerTarget.appendChild(input)
        })
    }

    hasTag(value) {
        return Array.from(this.containerTarget.querySelectorAll("li")).some(li => li.dataset.value === value)
    }
}
