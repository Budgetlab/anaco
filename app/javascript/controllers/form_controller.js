import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
  return ['form','submitBouton','fieldRequire', 'Btnvalidate','Btnsave','count','datealerte1','datealerte2','etat','dotation',
  ];
  }
  connect() {
    this.formChange();
    if (document.getElementById("commentaire") != null) {
      this.calculNombreCaracteres();
    }
    if (document.getElementById("ae_i") != null){
      this.setNombreInput();
    }
    if (document.getElementById("ae_f") != null){
      this.getEcart();
    }
  }

  formChange(){
    let isValid = this.validateForm(this.formTarget);
    if (isValid == true){
      this.BtnvalidateTarget.classList.remove('bouton_inactive');
      this.BtnvalidateTarget.disabled = false;
    } else {
      this.BtnvalidateTarget.classList.add('bouton_inactive');
      this.BtnvalidateTarget.disabled = true;
    }
  }

  setNombreInput(){
    const fields = document.querySelectorAll("input[type='text']");
    fields.forEach(field => {
      if (field.id != "commentaire" && field.id != "date_envoi" && field.id != "date_reception" && field.id != "date_document"){
        this.changeFloatToText(field);
      }
    });
  }

  calculNombreCaracteres(){
    const commentaire = document.getElementById("commentaire");
    this.countTarget.innerHTML = commentaire.value.length.toString()

    if (commentaire.value.length > 800){
      this.countTarget.parentElement.classList.add('cwarning')
    }else {
      this.countTarget.parentElement.classList.remove('cwarning')
    }
  }

  getEcart(){
    if (document.getElementById("ae_i") != null ){
      const ae_i = this.numberFormat(document.getElementById("ae_i").value) || 0;
      const ae_f = this.numberFormat(document.getElementById("ae_f").value) || 0;
      const ae_resultat = document.getElementById("ae_resultat");
      const cp_i = this.numberFormat(document.getElementById("cp_i").value) || 0;
      const cp_f = this.numberFormat(document.getElementById("cp_f").value) || 0;
      const cp_resultat = document.getElementById("cp_resultat");
      const t2_i = this.numberFormat(document.getElementById("t2_i").value) || 0;
      const t2_f = this.numberFormat(document.getElementById("t2_f").value) || 0;
      const t2_resultat = document.getElementById("t2_resultat");
      const etpt_i = this.numberFormat(document.getElementById("etpt_i").value) || 0;
      const etpt_f = this.numberFormat(document.getElementById("etpt_f").value) || 0;
      const etpt_resultat = document.getElementById("etpt_resultat");

      this.calculEcart(ae_i,ae_f,ae_resultat, "€");
      this.calculEcart(cp_i,cp_f,cp_resultat, "€");
      this.calculEcart(t2_i,t2_f,t2_resultat, "€");
      this.calculEcart(etpt_i,etpt_f,etpt_resultat, '');
    }
  }

  calculEcart(valeur_i, valeur_f, resultat, unite){
    resultat.innerHTML = (valeur_i - valeur_f).toLocaleString("fr-FR") + unite;
    if (valeur_i - valeur_f < 0){
      resultat.classList.add('crouge')
    }else{
      resultat.classList.remove('crouge')
    }
  }

  changeFloatToText(field){
    const parsedValue = this.numberFormat(field.value);
    if (!isNaN(parsedValue)) {
      // Formatage du nombre avec séparateur de milliers
      const formattedValue = parsedValue.toLocaleString("fr-FR");
      field.value = formattedValue;

    } else {
      field.value = null;
    }
  }
  changeNumber(event){
    const inputElement = event.target;
    const orginalLength = inputElement.value.length
    const end = inputElement.selectionEnd;
    let element = inputElement.value.replace(/[^0-9,-.]/g, "");
    element = element.replace(/,,/g, ',')
    const lastLetter = inputElement.value[inputElement.value.length - 1];
    if (inputElement.value.length == 1 && inputElement.value == "-"){
      inputElement.value = "-";
    }else{
      const parsedValue = this.numberFormat(element);
      if (!isNaN(parsedValue)) {
        // Formatage du nombre avec séparateur de milliers
        const formattedValue = parsedValue.toLocaleString("fr-FR");
        // Mettez à jour la valeur du champ de formulaire avec le format souhaité
        if (lastLetter == "," || lastLetter == "."){
          inputElement.value = formattedValue + ",";
        }else {
          inputElement.value = formattedValue;
        }
        const lengthDiff = inputElement.value.length - orginalLength ;
        inputElement.setSelectionRange(end + lengthDiff, end + lengthDiff);
      } else {
        inputElement.value = null;
      }
    }
    this.getEcart();

  }
  numberFormat(number){
    if (number != undefined){
      const sanitizedValue = number.replace(/\u202F/g, "");
      // Remplacez la virgule par un point pour permettre les décimaux
      const sanitizedValueWithDot = sanitizedValue.replace(',', '.');
      // Analysez la valeur en tant que nombre à virgule flottante
      const parsedValue = parseFloat(sanitizedValueWithDot);
      return parsedValue;
    }
  }

  changeTextToFloat(event){
    event.preventDefault();
    const fields = document.querySelectorAll("input[type='text']");
    fields.forEach(field => {
      if (field.id != "commentaire" && field.id != "date_envoi" && field.id != "date_reception" && field.id != "date_document") {
        const parsedValue = this.numberFormat(field.value);
        if (!isNaN(parsedValue)) {
          field.value = parsedValue;
        }
      }
    })
    this.formTarget.submit();
  }


  changeDateReception(e){
    e.preventDefault();
    const date_max = new Date(2024, 2, 1);
    const date_reception = document.getElementById("date_reception");
    this.setAlerteDate(date_reception, date_max, this.datealerte1Target );
  }
  changeDateEnvoi(e){
    e.preventDefault();
    const date_max = new Date(2024, 2, 15);
    const date_envoi = document.getElementById("date_envoi");
    this.setAlerteDate(date_envoi, date_max, this.datealerte2Target );
  }
  changeDateCRG1(e){
    e.preventDefault();
    const date_max = new Date(2024, 4, 15);
    const date_envoi = document.getElementById("date_envoi");
    this.setAlerteDate(date_envoi, date_max, this.datealerte2Target );
  }
  changeDateCRG2(e){
    e.preventDefault();
    const date_max = new Date(2024, 8, 15);
    const date_envoi = document.getElementById("date_envoi");
    this.setAlerteDate(date_envoi, date_max, this.datealerte2Target );
  }

  setAlerteDate(date, date_max, resultat){
    if (new Date(date.value.split('/').reverse().join('/')) > date_max){
      resultat.classList.remove('fr-hidden');
    }else{
      resultat.classList.add('fr-hidden');
    }
  }

  validateForm(){
    let isValid = true;
    this.fieldRequireTargets.forEach((field) => {
      if (field.value == "" && field.disabled == false){
        isValid = false;
      }
    })
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