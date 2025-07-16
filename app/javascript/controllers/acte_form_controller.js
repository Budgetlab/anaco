import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="form-submit"
export default class extends Controller {
    static targets = ["submitButton", "fieldRequire", "submitAction", "form", "message", "totalMontant","ecartMontant", "montantAeField", 'etatCheckbox', 'addButton']

    connect() {
        if (this.hasSubmitButtonTarget && this.submitButtonTarget.dataset.conditionsMet != undefined) {
            this.checkValidation()
        }

        this.setNombreInput();

        if (this.hasTotalMontantTarget) {
            this.updateTotal()
        }
        if (this.hasEtatCheckboxTarget) {
            this.toggleChorusFields()
        }
        if (this.hasAddButtonTarget){
            this.toggleAddButton()
        }
    }

    // pour check soumission à la validation
    checkValidation() {
        const allFieldsFilled = this.fieldRequireTargets.every(field => field.value.trim() !== "")
        const conditionsMet = this.submitButtonTarget.dataset.conditionsMet === "true"
        this.submitButtonTarget.disabled = !(allFieldsFilled && conditionsMet)
    }

    // pour check validation finale
    checkSubmission() {
        const allFieldsFilled = this.fieldRequireTargets.every(field => field.value.trim() !== "")
        this.submitButtonTarget.disabled = !allFieldsFilled
    }

    setValidation(event) {
        this.submitActionTarget.value = "en attente de validation"
    }

    setCloturePreInstruction(event){
        this.submitActionTarget.value = "clôturé après pré-instruction"
    }

    resetInstruction(event) {
        this.submitActionTarget.value = "en cours d'instruction"
        this.removeRequiredAndSubmit()
    }

    confirmValidation(event) {
        this.submitActionTarget.value = "en attente de validation Chorus"
    }

    confirmCloture(event) {
        this.submitActionTarget.value = "clôturé"
    }
    removeRequiredAndSubmit(){
        this.element.querySelectorAll('[required]').forEach(field => {
            field.removeAttribute('required');
        });
        this.element.submit();
    }

    setNombreInput() {
        const fields = document.querySelectorAll("[data-acte-form-number-field]");
        fields.forEach(field => {
            this.changeFloatToText(field);
        });
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
        // event.preventDefault();
        const fields = document.querySelectorAll("[data-acte-form-number-field]");
        fields.forEach(field => {
            if (field.value.includes(',')) {
                const parts = field.value.split(',');
                const integerPart = parts[0].replace(/\u202F/g, "");
                const decimalPart = parts[1] || "";

                // Convertir la partie entière en nombre
                let parsedInteger = parseFloat(integerPart.replace(',', '.'));
                if (isNaN(parsedInteger)) parsedInteger = 0;

                // Reconstruire la valeur pour la soumission (format avec point décimal)
                field.value = parsedInteger + "." + decimalPart;
            } else {
                const parsedValue = this.numberFormat(field.value);
                if (!isNaN(parsedValue)) {
                    field.value = parsedValue;
                }
            }
        });
        //this.formTarget.submit();
    }

    changeNumber(event) {
        const inputElement = event.target;
        const orginalLength = inputElement.value.length;
        const end = inputElement.selectionEnd;
        let element = inputElement.value.replace(/[^0-9,-.]/g, "");
        element = element.replace(/,,/g, ',');
        const lastLetter = inputElement.value[inputElement.value.length - 1];

        // Cas particulier pour le signe négatif seul
        if (inputElement.value.length == 1 && inputElement.value == "-") {
            inputElement.value = "-";
            return;
        }

        // Conservation des zéros après la virgule avec limite à 2 décimales
        if (element.includes(',')) {
            const parts = element.split(',');
            const integerPart = parts[0];
            let decimalPart = parts[1];

            // Limiter à 2 décimales maximum
            if (decimalPart.length > 2) {
                decimalPart = decimalPart.substring(0, 2);
            }

            // Traiter la partie entière avec le formatage
            let parsedInteger = this.numberFormat(integerPart);
            if (isNaN(parsedInteger)) parsedInteger = 0;
            const formattedInteger = parsedInteger.toLocaleString("fr-FR");

            // Reconstruire la valeur avec la partie décimale préservée et limitée
            if (lastLetter == "," || lastLetter == ".") {
                inputElement.value = formattedInteger + ",";
            } else {
                inputElement.value = formattedInteger + "," + decimalPart;
            }
        } else {
            // Comportement normal pour les nombres sans décimales
            const parsedValue = this.numberFormat(element);
            if (!isNaN(parsedValue)) {
                const formattedValue = parsedValue.toLocaleString("fr-FR");

                if (lastLetter == "," || lastLetter == ".") {
                    inputElement.value = formattedValue + ",";
                } else {
                    inputElement.value = formattedValue;
                }
            } else {
                inputElement.value = null;
            }
        }

        // Repositionner le curseur
        const lengthDiff = inputElement.value.length - orginalLength;
        inputElement.setSelectionRange(end + lengthDiff, end + lengthDiff);
    }

    toggleMessage() {
        const radioNon = document.getElementById('radio-false')
        if (radioNon && this.hasMessageTarget) {
            this.messageTarget.style.display = radioNon.checked ? '' : 'none'
        }
    }

    checkChorusNumberExistence(event) {
        const numero = event.target.value;
        const acteId = event.target.dataset.acteId || ""
        const typeActe = event.target.dataset.typeActe || "";
        const message = document.getElementById('message-chorus-number-existence')
        const url = this.data.get("checkchorusurl")
        const numero_size = numero.length
        const message_nombre = document.getElementById('message-chorus-number')
        let requiredLength = 10;
        if (typeActe === "TF") {
            requiredLength = 8;
        }
        if (numero_size !== requiredLength) {
            message.classList.add('fr-hidden')
            message_nombre.classList.remove('fr-hidden')
        } else {
            message_nombre.classList.add('fr-hidden')
            fetch(`${url}?acte_id=${acteId}&numero_chorus=${numero}`)
                .then(response => response.json())
                .then(data => {
                    if (data.exists) {
                        message.classList.remove('fr-hidden')
                    } else {
                        message.classList.add('fr-hidden')
                    }
                })
                .catch(error => {
                    console.error("Erreur lors de la vérification:", error)
                })
        }
    }

    updateTotal() {
        // Récupérer tous les champs de montant
        const montantFields = document.querySelectorAll('input[id="montant"]')

        // Calculer la somme
        let total = 0
        montantFields.forEach(field => {
            // Convertir en nombre et ajouter au total (en gérant les valeurs vides ou non numériques)
            const value = this.numberFormat(field.value) || 0
            total += value
        })

        // Afficher le total formaté
        this.totalMontantTarget.textContent = total.toLocaleString('fr-FR')
    }
    updateTotalDelete(){
        // Récupérer la ligne qui va être supprimée
        const ligneWrapper = event.target.closest('.nested-form-wrapper');

        // Récupérer le champ montant de cette ligne spécifique
        const montantField = ligneWrapper.querySelector('#montant');
        montantField.value = null;
        this.updateTotal()
    }

    calculerEcart() {
        // Vérifier si on a tous les éléments nécessaires pour calculer l'écart
        if (!this.hasEcartMontantTarget || !this.hasMontantAeFieldTarget) return

        const montantPrecedent = parseFloat(this.montantAeFieldTarget.dataset.montantPrecedent) || 0
        const montantActuel = this.numberFormat(this.montantAeFieldTarget.value)

        // Calculer l'écart
        const ecart = montantActuel - montantPrecedent

        // Formater l'écart avec le signe (+ ou -) et deux décimales
        const ecartFormate = ecart.toLocaleString('fr-FR')

        // Mise à jour de l'affichage
        this.ecartMontantTarget.textContent = ecartFormate
    }

    toggleChorusFields(){
        const is_checked = this.etatCheckboxTarget.checked
        const date_chorus = document.getElementById('date_chorus')
        const numero_chorus = document.getElementById('numero_chorus')

        if (!date_chorus || !numero_chorus) return;

        if (is_checked) {
            document.querySelectorAll('.chorus_fields').forEach(element => {
                element.classList.add('fr-hidden');
            })
            numero_chorus.value = null;
            date_chorus.value = null;

            // Retirer le required
            date_chorus.removeAttribute('required');

        } else {
            document.querySelectorAll('.chorus_fields').forEach(element => {
                element.classList.remove('fr-hidden');
            })
            // Ajouter le required
            date_chorus.setAttribute('required', 'required');
        }
    }
    togglePreInstruction(event){
        event.preventDefault();
        const is_checked = event.target.checked
        if (is_checked) {
            document.querySelectorAll('.pre_instruction_fields').forEach(element => {
                element.classList.add('fr-hidden');
            })
        } else {
            document.querySelectorAll('.pre_instruction_fields').forEach(element => {
                element.classList.remove('fr-hidden')
            })
        }
    }

    toggleAddButton() {

        // Récupérer la dernière .nested-form-wrapper
        const wrappers = this.element.querySelectorAll(".nested-form-wrapper")
        const lastWrapper = wrappers[wrappers.length - 1]
        if (!lastWrapper) {
            this.addButtonTarget.disabled = false
            return
        }

        const requiredInputs = lastWrapper.querySelectorAll(
            'input[id*="date_suspension"], select[id*="motif"], input[id*="date_reprise"]'
        )

        const allFilled = Array.from(requiredInputs).every(el => el.value && el.value.trim() !== "")

        this.addButtonTarget.disabled = !allFilled
    }

    removeDisable(){
        this.addButtonTarget.disabled = false
    }

    checkRepriseVsSuspension(event) {
        const wrapper = event.target.closest('.nested-form-wrapper');
        if (!wrapper) return;

        const dateSuspensionInput = wrapper.querySelector('[id^="date_suspension_"]');
        const dateRepriseInput = wrapper.querySelector('[id^="date_reprise_"]');
        const messageAlert = wrapper.querySelector('[id^="message-reprise-suspension-"]');

        if (!dateSuspensionInput || !dateRepriseInput || !messageAlert) return;

        const dateSuspension = dateSuspensionInput.value ? new Date(dateSuspensionInput.value.split("/").reverse().join("-")) : null;
        const dateReprise = dateRepriseInput.value ? new Date(dateRepriseInput.value.split("/").reverse().join("-")) : null;

        if (dateSuspension && dateReprise && dateReprise < dateSuspension) {
            messageAlert.classList.remove('fr-hidden');
        } else {
            messageAlert.classList.add('fr-hidden');
        }
    }
    checkDecision(event){
        const selectedValue = event.target.value;
        const date_cloture_wrapper = document.getElementById('date_cloture_wrapper');
        const cloture_button = document.getElementById('cloture_button');
        const date_cloture = document.getElementById('date_cloture');
        const validation_button = document.getElementById('validation_button');
        if (selectedValue === "Retour sans décision (sans suite)"){
            date_cloture_wrapper.classList.remove('fr-hidden');
            cloture_button.classList.remove('fr-hidden');
            validation_button.classList.add('fr-hidden');
            date_cloture.value = null;
            date_cloture.setAttribute('required', 'required');
        }else{
            date_cloture_wrapper.classList.add('fr-hidden');
            date_cloture.value = null;
            date_cloture.removeAttribute('required');
            cloture_button.classList.add('fr-hidden');
            validation_button.classList.remove('fr-hidden');
        }
    }

}
