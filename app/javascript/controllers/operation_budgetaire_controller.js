import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["natureField"]

    connect() {
        // Initialize wasRequired on first load
        if (this.hasNatureFieldTarget) {
            const select = this.natureFieldTarget.querySelector('select')
            if (select && !select.dataset.wasRequired) {
                select.dataset.wasRequired = select.required ? 'true' : 'false'
            }
        }
        // Initialize visibility on page load
        this.toggle()
    }

    toggle() {
        const selectElement = this.element.querySelector('#operation_budgetaire')
        if (!selectElement) return

        const selectedValue = selectElement.value

        // Vérifier si operation_compte_tiers est sur "oui"
        const operationCompteTiersOui = this.element.querySelector('#operation_compte_tiers_oui')
        const isOperationCompteTiers = operationCompteTiersOui && operationCompteTiersOui.checked

        if (this.hasNatureFieldTarget) {
            // Cacher le champ si operation_budgetaire est 'Globalisée' OU si operation_compte_tiers est sur "oui"
            if (selectedValue === 'Globalisée' || isOperationCompteTiers) {
                // Cacher le champ nature_categorie_organisme
                this.natureFieldTarget.classList.add('fr-hidden')
                // Retirer l'attribut required
                const select = this.natureFieldTarget.querySelector('select')
                if (select) {
                    if (!select.dataset.wasRequired) {
                        select.dataset.wasRequired = select.required ? 'true' : 'false'
                    }
                    select.required = false
                    // Vider le champ (remettre à la valeur par défaut)
                    select.value = ''
                }
            } else {
                // Afficher le champ nature_categorie_organisme seulement si operation_compte_tiers est sur "non" ET operation_budgetaire n'est pas 'Globalisée'
                this.natureFieldTarget.classList.remove('fr-hidden')
                // Restaurer l'attribut required si nécessaire
                const select = this.natureFieldTarget.querySelector('select')
                if (select) {
                    // Si wasRequired n'est pas défini, considérer que le champ est required par défaut
                    const shouldBeRequired = select.dataset.wasRequired === 'true' || !select.dataset.wasRequired
                    if (shouldBeRequired) {
                        select.required = true
                    }
                }
            }
        }
    }
}
