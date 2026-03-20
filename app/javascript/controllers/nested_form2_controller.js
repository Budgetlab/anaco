import NestedForm from '@stimulus-components/rails-nested-form'

export default class extends NestedForm {

  connect() {
    super.connect()
  }

  duplicate(event) {
    const wrapper = event.target.closest('.nested-form-wrapper')
    const clone = wrapper.cloneNode(true)
    const newIndex = new Date().getTime()

    // Remplacer tous les attributs name/id contenant l'index existant
    const currentIndex = wrapper.querySelector('[name]')
      ?.name.match(/\[(\d+)\]/)?.[1]

    clone.querySelectorAll('input, select, textarea').forEach(el => {
      if (currentIndex) {
        if (el.name) el.name = el.name.replace(`[${currentIndex}]`, `[${newIndex}]`)
        if (el.id)   el.id   = el.id.replace(currentIndex, newIndex)
      }
      // Réinitialiser _destroy
      if (el.name?.includes('_destroy')) el.value = 'false'
      // Ne pas dupliquer le champ numero
      if (el.name?.includes('[numero]')) el.value = ''
    })

    clone.dataset.newRecord = 'true'

    this.targetTarget.insertAdjacentElement('beforebegin', clone)

    // Recalculer le total montant via le controller acte-form
    const acteFormEl = this.element.closest('[data-controller~="acte-form"]')
    if (acteFormEl) {
      const acteFormController = this.application.getControllerForElementAndIdentifier(acteFormEl, 'acte-form')
      acteFormController?.updateTotalLignesPoste()
    }
  }

}