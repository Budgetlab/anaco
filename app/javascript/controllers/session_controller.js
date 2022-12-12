import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
  return ['form','statut','nom','nomBloc','password','submitBouton','error','error2','credentials'
  ];
  }

  connect() {
    
  }

  statutChange(e){
    e.preventDefault();
    if (this.statutTarget.value == "admin" || this.statutTarget.value == "" ){
      this.nomBlocTarget.classList.add('fr-hidden');
      this.resetChamp(this.nomTarget);
    }else if (this.statutTarget.value == "CBR" || this.statutTarget.value == "DCB"){
      this.nomBlocTarget.classList.remove('fr-hidden');
      this.resetChamp(this.nomTarget);
      // mettre à jour les valeurs dans nom 
      const statut = this.statutTarget.value;
      const token = document.querySelector('meta[name="csrf-token"]').content;
      const url = "/avisbop/select_nom";
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

  resetChamp(target){
        target.innerHTML = "";
        const option = document.createElement("option");
        option.value = "";
        option.innerHTML = "- Sélectionner -";
        target.appendChild(option);
  }

  changeForm(e){
    e.preventDefault();
    this.error2Target.classList.add('fr-hidden');
    this.errorTarget.classList.add('fr-hidden');
    this.credentialsTarget.classList.remove('fr-fieldset--error');
  }

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
      this.error2Target.classList.remove('fr-hidden');
      this.credentialsTarget.classList.add('fr-fieldset--error');
      e.preventDefault();
    }
  }

  resultForm(event){
    if (event.detail.success == false){
      this.errorTarget.classList.remove('fr-hidden');
      this.credentialsTarget.classList.add('fr-fieldset--error');
    } 
  }

}
