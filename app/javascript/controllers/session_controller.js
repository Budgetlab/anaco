import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
  return ['form','statut','nom','perimetre','password','credentials','erreurMDP','erreurOubli'];
  }

  connect() {
    
  }

  // fonction qui met à jour les noms dans le bloc périmètre
  statutChange(e){
    e.preventDefault();
    if (this.statutTarget.value == "admin" || this.statutTarget.value == "" ){
      this.perimetreTarget.classList.add('fr-hidden');
      this.resetChamp(this.nomTarget);
    }else if (this.statutTarget.value == "CBR" || this.statutTarget.value == "DCB"){
      this.perimetreTarget.classList.remove('fr-hidden');
      this.resetChamp(this.nomTarget);
      // récupérer et mettre à jour les valeurs des noms dans périmètre
      const statut = this.statutTarget.value;
      const token = document.querySelector('meta[name="csrf-token"]').content;
      const url = "/anaco/select_nom";
      const body = { statut }
      fetch(url, { 
          method: 'POST', 
          body: JSON.stringify(body),
          credentials: "include",
          dataType: 'script',
          headers: {
            "X-CSRF-Token": token,
            "Content-Type": "application/json"
          },
        })
        .then(response => response.json()/*response.text()*/)
        .then(data => {
            data.noms.forEach((nom) => {
            const opt = document.createElement("option");
            opt.value = nom;
            opt.innerHTML = nom;
            this.nomTarget.appendChild(opt);
            })
        })

    }
  }

    // fonction qui n'affiche plus que l'option vide "- Sélectionner -" dans les champs select
  resetChamp(target){
        target.innerHTML = "";
        const option = document.createElement("option");
        option.value = "";
        option.innerHTML = "- Sélectionner -";
        target.appendChild(option);
  }

  // fonction qui efface les messages d'erreur dès la modification d'un champ
  changeForm(e){
    e.preventDefault();
    this.erreurOubliTarget.classList.add('fr-hidden');
    this.erreurMDPTarget.classList.add('fr-hidden');
    this.credentialsTarget.classList.remove('fr-fieldset--error');
  }

    // fonction qui récupère les erreurs avant l'envoi du formulaire
  submitForm(e){
    let valid = true;
    if (this.passwordTarget.value == ""){
      valid = false;
    }
    if (this.statutTarget.value == "" ){
      valid = false;
    }
    if ((this.statutTarget.value == "CBR" || this.statutTarget.value == "DCB") && this.nomTarget.value == ""){
      valid = false;
    }
    if (valid == false ){
      this.erreurOubliTarget.classList.remove('fr-hidden');
      this.credentialsTarget.classList.add('fr-fieldset--error');
      e.preventDefault();
    }
  }

    // fonction qui récupère les erreurs du mot de passe après l'envoi du formulaire
  resultForm(event){
    if (event.detail.success == false){
      this.erreurMDPTarget.classList.remove('fr-hidden');
      this.credentialsTarget.classList.add('fr-fieldset--error');
    } 
  }

}
