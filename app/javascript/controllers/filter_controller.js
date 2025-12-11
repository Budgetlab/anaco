import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
    return ['form', 'tabField'];
  }
  connect() {
  }

  updateActiveTab() {
    // Trouver l'onglet actuellement sélectionné
    const activeTab = document.querySelector('.fr-tabs__tab[aria-selected="true"]');
    if (activeTab && this.hasTabFieldTarget) {
      // Mapper les IDs des onglets vers les noms
      const tabMap = {
        'storybook-tab-0': 'preinstruction',
        'storybook-tab-1': 'instruction',
        'storybook-tab-2': 'suspendu',
        'storybook-tab-3': 'validation',
        'storybook-tab-4': 'cloture',
        'storybook-tab-5': 'clotures'
      };
      const tabName = tabMap[activeTab.id] || 'validation';
      this.tabFieldTarget.value = tabName;
    }
  }

  getActiveTabName() {
    const activeTab = document.querySelector('.fr-tabs__tab[aria-selected="true"]');
    const tabMap = {
      'storybook-tab-0': 'preinstruction',
      'storybook-tab-1': 'instruction',
      'storybook-tab-2': 'suspendu',
      'storybook-tab-3': 'validation',
      'storybook-tab-4': 'cloture',
      'storybook-tab-5': 'clotures'
    };
    return activeTab ? (tabMap[activeTab.id] || 'validation') : 'validation';
  }

  resetWithTab(event) {
    event.preventDefault();
    const tabName = this.getActiveTabName();
    const link = event.currentTarget;
    const baseUrl = link.href.split('?')[0];
    const url = `${baseUrl}?tab=${tabName}`;

    // Naviguer avec Turbo Frame
    const turboFrame = link.dataset.turboFrame;
    if (turboFrame) {
      const frame = document.getElementById(turboFrame);
      if (frame) {
        frame.src = url;
      }
    } else {
      window.location.href = url;
    }
  }

  submitFilter(){
    this.formTarget.requestSubmit();
  }

  Dropdown(e){
    e.preventDefault();
  }

}