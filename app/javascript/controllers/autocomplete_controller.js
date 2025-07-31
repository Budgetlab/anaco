import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="form-submit"
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
                // this.hideNoResults()
            }
        })
    }

    // fonction qui appelle le contrôleur pendant la saisie pour rechercher les codes existants
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
                    // Vérifier si la saisie correspond exactement à un code dans la liste
                    const exactMatch = data.some(item => item.code === query.toUpperCase())
                    if (exactMatch) {
                        // le code renseigné correspond exactement à un code
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
            element.textContent = item.code
            element.dataset.action = "click->autocomplete#select"
            element.dataset.value = item.code
            this.resultsTarget.appendChild(element)
        })

        this.resultsTarget.hidden = false
    }

    // quand clique sur un choix de la liste déroulante, mets à jour le code dans input
    select(event) {
        this.inputTarget.value = event.currentTarget.dataset.value
        this.hideResults()
        this.hideNoResults()

        // Déclencher l'événement input pour le controller acte-form
        // const inputEvent = new Event('input', { bubbles: true })
        // this.inputTarget.dispatchEvent(inputEvent)
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