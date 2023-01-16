import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
  return ['form','submitBouton',
  'datereception','dateenvoi','statut','aei','cpi','t2i','etpti','aef','cpf','t2f','etptf','aeresult','cpresult','t2result','etptresult','commentaire',
  'Btnvalidate','Btnsave','count','datealerte1','datealerte2','etat',
  ];
  }
  connect() {
    //this.getEcart();
    this.formChange()
  }

  formChange(){
    //e.preventDefault();
    this.count();
    let isValid = this.validateForm(this.formTarget);

    this.getEcart();
    if (isValid == true){
      this.BtnvalidateTarget.classList.remove('bouton_inactive');
      this.BtnvalidateTarget.disabled = false;
    } else {
      this.BtnvalidateTarget.classList.add('bouton_inactive');
      this.BtnvalidateTarget.disabled = true;
    }
  }

  getEcart(){
    if (this.aeiTarget.value >= 0 && this.aefTarget.value >= 0 ){
      this.aeresultTarget.innerHTML = (parseFloat(Number(this.aeiTarget.value - this.aefTarget.value).toFixed(2))).toString()+"€"
      if (this.aeiTarget.value - this.aefTarget.value < 0){
        this.aeresultTarget.classList.add('crouge')
      }else{
        this.aeresultTarget.classList.remove('crouge')
      }
    }
    if (this.cpiTarget.value >= 0 && this.cpfTarget.value >= 0 ){
      this.cpresultTarget.innerHTML = (parseFloat(Number(this.cpiTarget.value - this.cpfTarget.value).toFixed(2))).toString()+"€"
      if (this.cpiTarget.value - this.cpfTarget.value < 0){
        this.cpresultTarget.classList.add('crouge')
      }else{
        this.cpresultTarget.classList.remove('crouge')
      }
    }
    if (this.t2iTarget.value >= 0 && this.t2fTarget.value >= 0 ){
      this.t2resultTarget.innerHTML = (parseFloat(Number(this.t2iTarget.value - this.t2fTarget.value).toFixed(2))).toString()+"€"
      if (this.t2iTarget.value - this.t2fTarget.value < 0){
        this.t2resultTarget.classList.add('crouge')
      }else{
        this.t2resultTarget.classList.remove('crouge')
      }
    }
    if (this.etptiTarget.value >= 0 && this.etptfTarget.value >= 0 ){
      this.etptresultTarget.innerHTML = (parseFloat(Number(this.etptiTarget.value - this.etptfTarget.value).toFixed(2))).toString()
      if (this.etptiTarget.value - this.etptfTarget.value < 0){
        this.etptresultTarget.classList.add('crouge')
      }else{
        this.etptresultTarget.classList.remove('crouge')
      }
    } 
  }

  count(){
    //e.preventDefault();
    this.countTarget.innerHTML = this.commentaireTarget.value.length.toString()

    if (this.commentaireTarget.value.length > 800){
      this.countTarget.parentElement.classList.add('cwarning')
    }else {
      this.countTarget.parentElement.classList.remove('cwarning')
    }
  }

  changeDate1(e){
    e.preventDefault();
    const date_max = new Date(2023, 2, 1); 
    if (new Date(this.datereceptionTarget.value.split('/').reverse().join('/')) > date_max){
      this.datealerte1Target.classList.remove('fr-hidden');
    }else{
      this.datealerte1Target.classList.add('fr-hidden');
    }


  }
  changeDate2(e){
    e.preventDefault();
    const date_max = new Date(2023, 2, 15)  
    if (new Date(this.dateenvoiTarget.value.split('/').reverse().join('/')) > date_max){
      this.datealerte2Target.classList.remove('fr-hidden');
    }else{
      this.datealerte2Target.classList.add('fr-hidden');
    }
  }
  changeDate3(e){
    e.preventDefault();
    const date_max = new Date(2023, 4, 15)
    if (new Date(this.dateenvoiTarget.value.split('/').reverse().join('/')) > date_max){
      this.datealerte2Target.classList.remove('fr-hidden');
    }else{
      this.datealerte2Target.classList.add('fr-hidden');
    }
  }

  validateForm(){
    let isValid = true;
    if (this.datereceptionTarget.value == "" || this.dateenvoiTarget.value == "" || this.statutTarget.selectedIndex == 0 || this.aeiTarget.value == "" || this.aefTarget.value == "" || this.cpiTarget.value == "" || this.cpfTarget.value == "" || this.t2iTarget.value == "" || this.t2fTarget.value == "" || this.etptiTarget.value == "" || this.etptfTarget.value == "" || this.commentaireTarget.value == ""){
      isValid = false;
    }
    return isValid
  }
  
  open(e){
    e.preventDefault(); 
    this.etatTarget.value = "En attente de lecture";   
  }
  save(e){
    e.preventDefault(); 
    this.etatTarget.value = "Brouillon";   
  }

  submitForm(event) {
    if (this.etatTarget.value == "En attente de lecture"){
      let isValid = this.validateForm(this.formTarget);
      if (!isValid) {
        event.preventDefault();
      }
    }
  }

}
function getSelectedValues(event) {
        return [...event.target.selectedOptions].map(option => option.value)
    }