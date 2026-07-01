import { Controller } from "@hotwired/stimulus"

// Navigation par onglets côté client pour le tableau de bord avis/notes.
// Affiche/masque les sections (panel) sans rechargement serveur et met à jour
// l'état actif du menu latéral (aria-current). Les graphes Highcharts rendus
// dans un panel masqué arrivent à 0px de large : on déclenche un reflow quand
// le panel devient visible.
export default class extends Controller {
  static targets = ["link", "panel"]

  connect() {
    const initial = window.location.hash?.replace('#', '')
    const target = this.panelTargets.find(p => p.dataset.tab === initial)
    this.show((target || this.panelTargets[0])?.dataset.tab)
  }

  select(event) {
    event.preventDefault()
    const tab = event.currentTarget.dataset.tab
    history.replaceState(null, '', `#${tab}`)
    this.show(tab)
  }

  show(tab) {
    if (!tab) return

    this.panelTargets.forEach(panel => {
      panel.hidden = panel.dataset.tab !== tab
    })

    this.linkTargets.forEach(link => {
      if (link.dataset.tab === tab) {
        link.setAttribute('aria-current', 'true')
      } else {
        link.removeAttribute('aria-current')
      }
    })

    // Les graphes Highcharts rendus dans un panel masqué arrivent à 0px de large.
    // Highcharts écoute window.resize : on le déclenche pour forcer le reflow
    // une fois le panel affiché.
    window.dispatchEvent(new Event('resize'))
  }
}
