import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
    static get targets() {
        return ['form', 'submitBouton', 'fieldRequire', 'Btnvalidate', 'Btnsave', 'count', 'datealerte1', 'datealerte2', 'etat', 'dotation',
            "aeInputs", "cpInputs","aeInputsNeg", "cpInputsNeg", "soldeAe", "soldeCp", "soldePrevAe", "soldePrevCp", 'soldePrevReportsAe', "soldePrevReportsCp"
        ];
    }

    connect() {
        this.formChange();
        if (this.countTargets.length > 0) {
            this.calculNombreCaracteres();
        }
        if (document.getElementById("ae_i") != null || document.getElementById('form_schema') != null) {
            this.setNombreInput();
        }
        if (document.getElementById("ae_i") != null && document.getElementById("ae_f") != null) {
            this.getEcart();
        }
        if (this.soldeAeTargets.length > 0) {
            this.calculateSoldePrev();
            this.calculateBalance();
            if (document.getElementById("fongibilite_cas") != null) {
                this.ChangeFongibiliteHCAS();
            }else if (document.getElementById("fongibilite_cp_input") != null){
                this.ChangeFongibilite();
            }
        }
    }

    formChange() {
        let isValid = this.validateForm(this.formTarget);
        if (isValid == true) {
            this.BtnvalidateTarget.classList.remove('bouton_inactive');
            this.BtnvalidateTarget.disabled = false;
        } else {
            this.BtnvalidateTarget.classList.add('bouton_inactive');
            this.BtnvalidateTarget.disabled = true;
        }
    }

    setNombreInput() {
        const fields = document.querySelectorAll("input[type='text']");
        fields.forEach(field => {
            if (field.id != "commentaire" && field.id != "date_envoi" && field.id != "date_reception" && field.id != "date_document") {
                this.changeFloatToText(field);
            }
        });
    }

    calculNombreCaracteres() {
        const commentaire = document.getElementById("commentaire");
        this.countTarget.innerHTML = commentaire.value.length.toString()

        if (commentaire.value.length > 800) {
            this.countTarget.parentElement.classList.add('cwarning')
        } else {
            this.countTarget.parentElement.classList.remove('cwarning')
        }
    }

    getEcart() {
        if (document.getElementById("ae_f") != null) {
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

            this.calculEcart(ae_i, ae_f, ae_resultat, "€");
            this.calculEcart(cp_i, cp_f, cp_resultat, "€");
            this.calculEcart(t2_i, t2_f, t2_resultat, "€");
            this.calculEcart(etpt_i, etpt_f, etpt_resultat, '');
        }
    }

    calculEcart(valeur_i, valeur_f, resultat, unite) {
        resultat.innerHTML = (valeur_i - valeur_f).toLocaleString("fr-FR") + unite;
        if (valeur_i - valeur_f < 0) {
            resultat.classList.add('crouge')
        } else {
            resultat.classList.remove('crouge')
        }
    }

    changeFloatToText(field) {
        const parsedValue = this.numberFormat(field.value);
        if (!isNaN(parsedValue)) {
            // Formatage du nombre avec séparateur de milliers
            const formattedValue = parsedValue.toLocaleString("fr-FR");
            field.value = formattedValue;

        } else {
            field.value = null;
        }
    }

    changeNumberPositive(event) {
        const inputElement = event.target;
        const end = inputElement.selectionEnd;
        const orginalLength = inputElement.value.length
        // Supprimez tous les caractères non numériques
        let element = inputElement.value.replace(/[^0-9]/g, "");
        const parsedValue = this.numberFormat(element);
        if (!isNaN(parsedValue)) {
            // Formatage du nombre avec séparateur de milliers
            const formattedValue = parsedValue.toLocaleString("fr-FR");
            // Mettez à jour la valeur du champ de formulaire avec le format souhaité
            inputElement.value = formattedValue;
            const lengthDiff = inputElement.value.length - orginalLength;
            inputElement.setSelectionRange(end + lengthDiff, end + lengthDiff);
        } else {
            inputElement.value = null;
        }

        if (this.soldeAeTargets.length > 0) {
            if (document.getElementById("fongibilite_cas") != null) {
                this.ChangeFongibiliteHCAS();
            } else if (document.getElementById("fongibilite_cp_input") != null){
                this.ChangeFongibilite();
            }
            this.calculateSoldePrev();
            this.calculateBalance();
        }

    }

    changeNumberNegative(event) {
        const inputElement = event.target;
        const end = inputElement.selectionEnd;
        let orginalLength = inputElement.value.length
        // Supprimez tous les caractères non numériques
        let element = inputElement.value.replace(/[^0-9-]/g, "");
        // Si la valeur ne commence pas par un '-', ajoutez-le
        if (!element.startsWith('-') && !element.startsWith('0')) {
            element = '-' + element;
        }
        // Enlevez tout signe moins supplémentaire qui pourrait exister dans la chaîne
        // après le premier caractère
        element = element[0] + element.slice(1).replace(/-/g, '');
        if (inputElement.value.length == 1 && inputElement.value == "-") {
            inputElement.value = "-";
        } else {
            const parsedValue = this.numberFormat(element);
            if (!isNaN(parsedValue)) {
                // Formatage du nombre avec séparateur de milliers
                const formattedValue = parsedValue.toLocaleString("fr-FR");
                // Mettez à jour la valeur du champ de formulaire avec le format souhaité
                inputElement.value = formattedValue;
                const lengthDiff = inputElement.value.length - orginalLength;
                inputElement.setSelectionRange(end + lengthDiff, end + lengthDiff);
            } else {
                inputElement.value = null;
            }

            if (this.soldeAeTargets.length > 0) {
                this.calculateSoldePrev();
                this.calculateBalance();
            }
        }

    }

    changeNumber(event) {
        const inputElement = event.target;
        const orginalLength = inputElement.value.length
        const end = inputElement.selectionEnd;
        let element = inputElement.value.replace(/[^0-9,-.]/g, "");
        element = element.replace(/,,/g, ',')
        const lastLetter = inputElement.value[inputElement.value.length - 1];
        if (inputElement.value.length == 1 && inputElement.value == "-") {
            inputElement.value = "-";
        } else {
            const parsedValue = this.numberFormat(element);
            if (!isNaN(parsedValue)) {
                // Formatage du nombre avec séparateur de milliers
                const formattedValue = parsedValue.toLocaleString("fr-FR");
                // Mettez à jour la valeur du champ de formulaire avec le format souhaité
                if (lastLetter == "," || lastLetter == ".") {
                    inputElement.value = formattedValue + ",";
                } else {
                    inputElement.value = formattedValue;
                }
                const lengthDiff = inputElement.value.length - orginalLength;
                inputElement.setSelectionRange(end + lengthDiff, end + lengthDiff);
            } else {
                inputElement.value = null;
            }
        }
        this.getEcart();

        if (this.soldeAeTargets.length > 0) {
            this.calculateSoldePrev();
            this.calculateBalance();
        }

    }

    numberFormat(number) {
        if (number != undefined) {
            const sanitizedValue = number.replace(/\u202F/g, "");
            // Remplacez la virgule par un point pour permettre les décimaux
            const sanitizedValueWithDot = sanitizedValue.replace(',', '.');
            // Analysez la valeur en tant que nombre à virgule flottante
            const parsedValue = parseFloat(sanitizedValueWithDot);
            return parsedValue;
        }
    }

    changeTextToFloat(event) {
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

    setAlerteDate(date, date_max, resultat) {
        if (new Date(date.value.split('/').reverse().join('/')) > date_max) {
            resultat.classList.remove('fr-hidden');
        } else {
            resultat.classList.add('fr-hidden');
        }
    }

    validateForm() {
        let isValid = true;
        this.fieldRequireTargets.forEach((field) => {
            if (field.value == "" && field.disabled == false) {
                isValid = false;
            }
        })
        return isValid
    }

    open(e) {
        e.preventDefault();
        this.etatTarget.value = "En attente de lecture";
        const fields = document.querySelectorAll("input[type='text'],textarea");
        let field_empty = Array.from(fields).some(field => field.value === '');
        const alert_message = document.getElementById("alert_field_empty")
        if (field_empty) {
            alert_message.classList.remove("fr-hidden");
        } else {
            alert_message.classList.add("fr-hidden");
        }

    }

    save(e) {
        e.preventDefault();
        this.etatTarget.value = "Brouillon";
    }

    setValide(e) {
        e.preventDefault();
        this.etatTarget.value = "valide";
    }

    submitForm(event) {
        if (this.etatTarget.value == "En attente de lecture") {
            let isValid = this.validateForm(this.formTarget);
            if (!isValid) {
                event.preventDefault();
            }
        }
    }

    calculateSoldePrev(){
        let soldeAe = 0;
        let soldeCp = 0;

        // ressources
        const ressources_ae = this.numberFormat(document.getElementById("ressources_ae").value) || 0
        const ressources_cp = this.numberFormat(document.getElementById("ressources_cp").value) || 0
        // depenses
        const depenses_ae = this.numberFormat(document.getElementById("depenses_ae").value) || 0
        const depenses_cp = this.numberFormat(document.getElementById("depenses_cp").value) || 0

        soldeAe = ressources_ae + depenses_ae
        soldeCp = ressources_cp + depenses_cp

        // update the balance fields
        this.soldePrevAeTarget.innerText = soldeAe.toLocaleString("fr-FR") + ' €';
        this.soldePrevCpTarget.innerText = soldeCp.toLocaleString("fr-FR") + ' €';

        this.updateCard(soldeAe, this.soldePrevAeTarget);
        this.updateCard(soldeCp, this.soldePrevCpTarget);
        if (document.getElementById("reports_ae") != null){
            this.calculateSoldePrevReports(soldeAe, soldeCp)
        }

    }

    calculateSoldePrevReports(soldeAe, soldeCp){
        // reports
        const reports_ae = this.numberFormat(document.getElementById("reports_ae").value) || 0
        const reports_cp = this.numberFormat(document.getElementById("reports_cp").value) || 0

        soldeAe = soldeAe + reports_ae
        soldeCp = soldeCp + reports_cp

        // update the balance fields
        this.soldePrevReportsAeTarget.innerText = soldeAe.toLocaleString("fr-FR") + ' €';
        this.soldePrevReportsCpTarget.innerText = soldeCp.toLocaleString("fr-FR") + ' €';

        this.updateCard(soldeAe, this.soldePrevReportsAeTarget);
        this.updateCard(soldeCp, this.soldePrevReportsCpTarget);
    }

    calculateBalance() {
        let aeBalance = 0;
        let cpBalance = 0;

        // calculate ae balance
        this.aeInputsTargets.forEach((input) => {
            let value = this.numberFormat(input.value);
            if (!isNaN(value)) {
                aeBalance += value;
            }
        });

        // calculate cp balance
        this.cpInputsTargets.forEach((input) => {
            let value = this.numberFormat(input.value);
            if (!isNaN(value)) {
                cpBalance += value;
            }
        });

        // update the balance fields
        this.soldeAeTarget.innerText = aeBalance.toLocaleString("fr-FR") + ' €';
        this.soldeCpTarget.innerText = cpBalance.toLocaleString("fr-FR") + ' €';

        this.updateCard(aeBalance, this.soldeAeTarget)
        this.updateCard(cpBalance, this.soldeCpTarget)

    }

    updateCard(amount, target) {
        let parentCard = target.closest('.fr-card');
        if (amount < 0) {
            parentCard.classList.remove("fr-card--blue")
            parentCard.classList.add("fr-card--red")
        } else {
            parentCard.classList.remove("fr-card--red")
            parentCard.classList.add("fr-card--blue")
        }
    }

    ChangeFongibiliteHCAS(){
        const fongibilite_hcas = this.numberFormat(document.getElementById("fongibilite_hcas").value) || 0
        const fongibilite_cas_input = document.getElementById("fongibilite_cas_input")
        const fongibilite_cas = document.getElementById("fongibilite_cas")
        fongibilite_cas_input.value = -fongibilite_hcas
        const value = -fongibilite_hcas
        fongibilite_cas.innerText = value.toLocaleString("fr-FR") + ' €';
    }

    ChangeFongibilite(){
        const fongibilite_ae = this.numberFormat(document.getElementById("fongibilite_ae").value) || 0
        const fongibilite_cp_input = document.getElementById("fongibilite_cp_input")
        const fongibilite_cp = document.getElementById("fongibilite_cp")
        fongibilite_cp_input.value = fongibilite_ae
        fongibilite_cp.innerText = fongibilite_ae.toLocaleString("fr-FR") + ' €';
    }

    saveDraft(event){
        this.changeTextToFloat(event);
        event.preventDefault()
        var form = this.formTarget
        var input = document.createElement("input")
        input.setAttribute("type", "hidden")
        input.setAttribute("name", "brouillon")
        input.setAttribute("value", "true")
        form.appendChild(input)
        form.submit()
    }

    preventDefault(event) {
        event.preventDefault()
    }

}

function getSelectedValues(event) {
    return [...event.target.selectedOptions].map(option => option.value)
}