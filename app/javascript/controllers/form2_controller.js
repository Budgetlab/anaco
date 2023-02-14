import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
  return ['form','submitBouton','dotation',
  ];
  }
  connect() {
    this.validateForm();
  }

  changeDotation(e){
    e.preventDefault();
    this.validateForm();
  }
  validateForm(){
    if (this.dotationTarget.value != ""){
      this.submitBoutonTarget.classList.remove('bouton_inactive');
      this.submitBoutonTarget.disabled = false;
    } else {
      this.submitBoutonTarget.classList.add('bouton_inactive');
      this.submitBoutonTarget.disabled = true;
    }
  }

}
function getSelectedValues(event) {
        return [...event.target.selectedOptions].map(option => option.value)
    }