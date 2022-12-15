import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
  return ['form','submitBouton',
  'datereception',
  ];
  }
  connect() {
    
  }

  formChange(e){
    e.preventDefault();
    let isValid = this.validateForm(this.formTarget);

  }


  resetChamp(target){
        target.innerHTML = "";
        const option = document.createElement("option");
        option.value = "";
        option.innerHTML = "- sélectionner -";
        target.appendChild(option);
    }


  validateForm(){
    let isValid = true;

    return isValid
  }
  preview(e){
    e.preventDefault();
    let isValid = this.validateForm(this.formTarget);
    
  }

  modifier(e){
    e.preventDefault();

  }

  replaceHtml(form, result){
    if (form.value == ""){
        result.innerHTML = "∅";
    }else{
        result.innerHTML = form.value;
    }
  }


}
function getSelectedValues(event) {
        return [...event.target.selectedOptions].map(option => option.value)
    }