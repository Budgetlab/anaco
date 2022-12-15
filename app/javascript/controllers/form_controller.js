import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
  return ['form','submitBouton',
  'datereception','dateenvoi','statut','aei','cpi','t2i','etpti','aef','cpf','t2f','etptf','aeresult','cpresult','t2result','etptresult','commentaire',
  'Btnvalidate','Btnsave','count','datealerte1','datealerte2',
  ];
  }
  connect() {
    
  }

  formChange(e){
    e.preventDefault();
    let isValid = this.validateForm(this.formTarget);

  }

  count(e){
    e.preventDefault();
  }

  changeDate1(e){
    e.preventDefault();
    const date_max = new Date(2023, 2, 1);  
    console.log(this.datereceptionTarget.value);
    console.log(new Date(this.datereceptionTarget.value) < date_max);

  }
  changeDate2(e){
    e.preventDefault();
    const date_max = new Date(2023, 2, 15)  
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
  save(e){
    e.preventDefault();
    let isValid = this.validateForm(this.formTarget);
    
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