import {Controller} from "@hotwired/stimulus"

// Controller for organisme autocomplete
export default class extends Controller {
    static targets = ["input", "results", "noResults"]
    static values = {url: String}

    connect() {
        this.resultsTarget.hidden = true
        if (this.hasNoResultsTarget) {
            this.noResultsTarget.classList.add("fr-hidden")
        }
        this.setupClickOutsideListener()
    }

    setupClickOutsideListener() {
        document.addEventListener('click', (event) => {
            if (!this.element.contains(event.target)) {
                this.hideResults()
            }
        })
    }

    // fonction qui appelle le contrôleur pendant la saisie pour rechercher les organismes existants
    search() {
        const query = this.inputTarget.value.trim()

        if (query.length < 1) {
            this.hideResults()
            this.hideNoResults()
            return
        }

        fetch(`${this.urlValue}?query=${encodeURIComponent(query)}`)
            .then(response => response.json())
            .then(data => {
                if (data.length === 0) {
                    this.hideResults()
                    this.showNoResults()
                } else {
                    this.showResults(data)
                    // Vérifier si la saisie correspond exactement à un nom, acronyme ou format "Acronyme - Nom"
                    const exactMatch = data.some(item => {
                        const fullFormat = item.acronyme ? `${item.acronyme} - ${item.nom}` : item.nom
                        return item.nom.toLowerCase() === query.toLowerCase() ||
                            (item.acronyme && item.acronyme.toLowerCase() === query.toLowerCase()) ||
                            fullFormat.toLowerCase() === query.toLowerCase()
                    })
                    if (exactMatch) {
                        // le nom, acronyme ou format complet renseigné correspond exactement à un organisme
                        this.hideNoResults()
                    } else {
                        this.showNoResults()
                    }
                }
            })
    }

    showResults(data) {
        this.resultsTarget.innerHTML = ""

        data.forEach(item => {
            const element = document.createElement("div")
            element.classList.add("autocomplete-item")
            // Afficher sous la forme "Acronyme - Nom" ou juste "Nom" si pas d'acronyme
            element.textContent = item.acronyme ? `${item.acronyme} - ${item.nom}` : item.nom
            element.dataset.action = "click->autocomplete-organisme#select"
            element.dataset.value = item.nom
            element.dataset.acronyme = item.acronyme || ''
            element.dataset.id = item.id
            this.resultsTarget.appendChild(element)
        })

        this.resultsTarget.hidden = false
    }

    // quand clique sur un choix de la liste déroulante, mets à jour le nom dans input
    select(event) {
        const acronyme = event.currentTarget.dataset.acronyme
        const nom = event.currentTarget.dataset.value
        // Afficher au format "Acronyme - Nom" ou juste "Nom" si pas d'acronyme
        this.inputTarget.value = acronyme ? `${acronyme} - ${nom}` : nom
        this.hideResults()
        this.hideNoResults()
    }

    hideResults() {
        this.resultsTarget.hidden = true
    }

    showNoResults() {
        if (this.hasNoResultsTarget) {
            this.noResultsTarget.classList.remove("fr-hidden")
        }
    }

    hideNoResults() {
        if (this.hasNoResultsTarget) {
            this.noResultsTarget.classList.add("fr-hidden")
        }
    }
}
