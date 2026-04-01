import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "dropdown", "item", "checkbox", "profilSelect"]

  connect() {
    this.updateCount()
    if (this.hasProfilSelectTarget) {
      this.filterByProfil()
    }
  }

  toggleDropdown() {
    const isVisible = this.dropdownTarget.style.display !== 'none'
    this.dropdownTarget.style.display = isVisible ? 'none' : 'block'
  }

  updateCount() {
    const checkedBoxes = this.checkboxTargets.filter(cb => cb.checked)
    const count = checkedBoxes.length
    this.buttonTarget.textContent = count > 0
      ? `Sélectionner des contrôleurs (${count})`
      : 'Sélectionner des contrôleurs'
  }

  filterByProfil() {
    const selectedProfil = this.profilSelectTarget.value

    this.itemTargets.forEach(item => {
      const itemStatut = item.dataset.statut

      if (selectedProfil === '' || selectedProfil === itemStatut) {
        item.style.display = 'block'
      } else {
        item.style.display = 'none'
        // Décocher les checkboxes qui ne correspondent pas au profil
        const checkbox = item.querySelector('input[type="checkbox"]')
        if (checkbox && checkbox.checked) {
          checkbox.checked = false
        }
      }
    })

    this.updateCount()
  }
}
