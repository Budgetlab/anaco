import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["dateReprise", "errorDateReprise", "warningDateReprise", "submit"]

    checkDateReprise() {
        const input = this.dateRepriseTarget
        const errorEl = this.errorDateRepriseTarget
        const warningEl = this.warningDateRepriseTarget

        const dateRepriseStr = input.value
        const dateSuspensionStr = input.dataset.dateSuspension

        if (!dateRepriseStr) {
            input.setCustomValidity('')
            errorEl.classList.add('fr-hidden')
            warningEl.classList.add('fr-hidden')
            return
        }

        const parseLocalDate = (str) => {
            const [y, m, d] = str.split('-').map(Number)
            return new Date(y, m - 1, d)
        }
        const dateReprise = parseLocalDate(dateRepriseStr)
        const dateSuspension = dateSuspensionStr ? parseLocalDate(dateSuspensionStr) : null

        const today = new Date()
        today.setHours(0, 0, 0, 0)

        if (dateSuspension && dateReprise < dateSuspension) {
            input.setCustomValidity('La date de reprise ne peut pas être antérieure à la date d\'interruption')
            errorEl.classList.remove('fr-hidden')
            warningEl.classList.add('fr-hidden')
        } else if (dateReprise > today) {
            input.setCustomValidity('')
            warningEl.classList.remove('fr-hidden')
            errorEl.classList.add('fr-hidden')
        } else {
            input.setCustomValidity('')
            errorEl.classList.add('fr-hidden')
            warningEl.classList.add('fr-hidden')
        }
    }
}
