import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["yearSelect", "dateFrom", "dateTo"]

  connect() {
    // Initialiser les limites au chargement
    if (this.hasYearSelectTarget && this.hasDateFromTarget && this.hasDateToTarget) {
      this.updateDateRange()
    }
  }

  updateDateRange() {
    const selectedYear = this.yearSelectTarget.value

    if (!selectedYear) return

    // Définir les dates min et max pour l'année sélectionnée
    const minDate = `${selectedYear}-01-01`
    const maxDate = `${selectedYear}-12-31`

    // Mettre à jour les attributs min et max des champs date
    if (this.hasDateFromTarget) {
      this.dateFromTarget.min = minDate
      this.dateFromTarget.max = maxDate

      // Réinitialiser la valeur si elle est en dehors de la plage
      if (this.dateFromTarget.value) {
        const currentValue = new Date(this.dateFromTarget.value)
        const minDateObj = new Date(minDate)
        const maxDateObj = new Date(maxDate)

        if (currentValue < minDateObj || currentValue > maxDateObj) {
          this.dateFromTarget.value = ''
        }
      }
    }

    if (this.hasDateToTarget) {
      this.dateToTarget.min = minDate
      this.dateToTarget.max = maxDate

      // Réinitialiser la valeur si elle est en dehors de la plage
      if (this.dateToTarget.value) {
        const currentValue = new Date(this.dateToTarget.value)
        const minDateObj = new Date(minDate)
        const maxDateObj = new Date(maxDate)

        if (currentValue < minDateObj || currentValue > maxDateObj) {
          this.dateToTarget.value = ''
        }
      }
    }
  }
}
