import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="form-submit"
export default class extends Controller {
    static targets = ["submitButton", "fieldRequire", "submitAction", "form", "message", "totalMontant", 'totalMontantEcheancierAE', 'totalMontantEcheancierCP', 'etatRadio', 'preRadio', 'decision', 'typeEngagement', 'montantAe', 'etatClotureRadio', "toggleSuspensionButton"]
    static values = { prefixes: Object }
    connect() {

        this.setNombreInput();

        if (this.hasTotalMontantTarget) {
            this.updateTotalLignesPoste()
        }
        if (this.hasTotalMontantEcheancierAETarget && this.hasTotalMontantEcheancierCPTarget) {
            this.updateTotalEcheancier()
        }
        if (this.hasDecisionTarget){
            this.checkDecision()
        }
        if (this.hasEtatRadioTarget){
            // modal nouvel acte
            this.togglePreInstruction()
        }
        if (this.hasEtatClotureRadioTarget){
            this.toggleCloture()
        }
    }
    setValidation(event) {
        this.submitActionTarget.value = "en attente de validation"
    }

    confirmCloture(event) {
        this.submitActionTarget.value = "clôturé"
    }

    // fonction pour enlever les required true pour la sauvegarde
    removeRequiredAndSubmit(){
        this.element.querySelectorAll('[required]').forEach(field => {
            field.removeAttribute('required');
        });
        //this.element.submit();
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
        // ICI on applique la règle "toujours négatif" si c'est un retrait pour montant AE
        if (this.hasMontantAeTarget && inputElement === this.montantAeTarget) {
            this.ensureNegativeIfNeeded(inputElement)
        }

        // Repositionner le curseur
        const lengthDiff = inputElement.value.length - orginalLength;
        inputElement.setSelectionRange(end + lengthDiff, end + lengthDiff);

    }

    changeType() {
        this.ensureNegativeIfNeeded(this.montantAeTarget)
    }

    ensureNegativeIfNeeded(inputElement) {
        // Si le type est un retrait, on force le signe négatif
        const type = this.typeEngagementTarget?.value
        const isRetrait = ["Retrait d'engagement", "Retrait"].includes(type)

        // Laisser passer le cas où l'utilisateur tape juste "-"
        if (inputElement.value === "-" || inputElement.value.trim() === "") return

        if (isRetrait) {
            // force le signe négatif
            if (!inputElement.value.trim().startsWith("-")) {
                inputElement.value = "-" + inputElement.value.trim()
            }
        } else {
            // optionnel : si tu veux retirer le "-" quand ce n'est PAS un retrait
            inputElement.value = inputElement.value.replace(/^\s*-/, "")
        }
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
        if (numero_size > 0 && numero_size !== requiredLength) {
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
                        message.classList.add('fr-hidden');
                    }
                })
                .catch(error => {
                    console.error("Erreur lors de la vérification:", error)
                })
        }
    }

    checkNumeroNatureChorus(){
        const message_nature = document.getElementById('message-chorus-nature')
        const selectedNature = document.getElementById('nature').value
        const numeroChorus = document.getElementById('numero_chorus').value
        // Si pas de nature sélectionnée ou pas de numéro, masquer l'alerte
        if (!selectedNature || !numeroChorus) {
            message_nature.classList.add('fr-hidden')
            return
        }
        // Vérifier si cette nature a un préfixe attendu
        const expectedPrefix = this.prefixesValue[selectedNature]
        if (!expectedPrefix) {
            // Pas de règle pour cette nature, masquer l'alerte
            message_nature.classList.add('fr-hidden')
            return
        }

        // Vérifier si le numéro commence par le bon préfixe
        if (!numeroChorus.startsWith(expectedPrefix)) {
            message_nature.textContent =
                `Le numéro Chorus pour "${selectedNature}" devrait commencer par "${expectedPrefix}".`
            message_nature.classList.remove('fr-hidden')
        } else {
            message_nature.classList.add('fr-hidden')
        }
    }

    checkNumeroMarcheLength(event){
        // action pour verifier numero de marché a 10 caractères
        const numero = event.target.value;
        const numero_size = numero.length
        let requiredLength = 10;
        const message_nombre = document.getElementById('message-marche-number')
        if (numero_size > 0 && numero_size !== requiredLength) {
            message_nombre.classList.remove('fr-hidden')
        }else{
            message_nombre.classList.add('fr-hidden')
        }
    }

    updateTotalLignesPoste() {
        // récupérer bloc
        const montant_card = document.getElementById('total_postes_card')
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

        // afficher le bloc si lignes présentes
        if (montantFields.length === 0 || (montantFields.length === 1 && total === 0)) { // gérer le cas ou supp unique ligne de post length == 1
            montant_card.classList.add('fr-hidden')
        }else{
            montant_card.classList.remove('fr-hidden')
        }
    }
    updateTotalDelete(){
        // Récupérer la ligne qui va être supprimée
        const ligneWrapper = event.target.closest('.nested-form-wrapper');

        // Récupérer le champ montant de cette ligne spécifique
        const montantField = ligneWrapper.querySelector('#montant');
        montantField.value = null;
        this.updateTotalLignesPoste()
    }

    updateTotalEcheancier(){
        // récupérer bloc
        const montant_card = document.getElementById('total_echeancier_card')
        // Récupérer tous les champs de montant
        const montantFields_cp = document.querySelectorAll('input[id="echeancier_cp"]')
        // Calculer la somme
        let total_cp = 0
        montantFields_cp.forEach(field => {
            // Convertir en nombre et ajouter au total (en gérant les valeurs vides ou non numériques)
            const value = this.numberFormat(field.value) || 0
            total_cp += value
        })
        // Afficher le total formaté
        this.totalMontantEcheancierCPTarget.textContent = total_cp.toLocaleString('fr-FR')

        // Récupérer tous les champs de montant
        const montantFields_ae = document.querySelectorAll('input[id="echeancier_ae"]')
        // Calculer la somme
        let total_ae = 0
        montantFields_ae.forEach(field => {
            // Convertir en nombre et ajouter au total (en gérant les valeurs vides ou non numériques)
            const value = this.numberFormat(field.value) || 0
            total_ae += value
        })

        // Afficher le total formaté
        this.totalMontantEcheancierAETarget.textContent = total_ae.toLocaleString('fr-FR')

        // afficher le bloc si lignes présentes
        if (montantFields_cp.length === 0 || (montantFields_cp.length === 1 && total_cp === 0 && total_ae ===0)) { // gérer le cas ou supp unique ligne de post length == 1
            montant_card.classList.add('fr-hidden')
        }else{
            montant_card.classList.remove('fr-hidden')
        }
    }

    updateTotalDeleteEcheancier(){
        // Récupérer la ligne qui va être supprimée
        const ligneWrapper = event.target.closest('.nested-form-wrapper');

        // Récupérer le champ montant de cette ligne spécifique
        const montantField_ae = ligneWrapper.querySelector('#echeancier_ae');
        const montantField_cp = ligneWrapper.querySelector('#echeancier_cp');
        montantField_ae.value = null;
        montantField_cp.value = null;
        this.updateTotalEcheancier();
    }

    // Modal affichage choix pre instruction si en cours d'instruction
    togglePreInstruction(event){
        const selected = this.etatRadioTargets.find(r => r.checked)?.value
        const show = selected === "en cours d'instruction"

        // afficher/cacher le bloc
        const bloc = document.getElementById('pre-instruction-block')
        bloc.hidden = !show

        // activer/désactiver + gérer required/checked
        this.preRadioTargets.forEach((el, idx) => {
            if (!show) el.checked = false
            el.required = show && idx === 0 //
        })

        // ➕ par défaut : si le bloc est visible et qu'aucun choix n'est coché, cocher "Non"
        if (show && !this.preRadioTargets.some(r => r.checked)) {
            const non = this.preRadioTargets.find(r => r.id === 'pre_instruction_no' || r.value === 'false')
            if (non) non.checked = true
        }
    }

    toggleCloture(event){
        const selected = this.etatClotureRadioTargets.find(r => r.checked)?.value
        const show = selected === "clôturé"

        // afficher/cacher le bloc
        const bloc = document.getElementById('cloture-date-block')
        bloc.hidden = !show
        console.log(bloc.hidden)

        const date_cloture = document.getElementById('date_cloture')
        if (!show) date_cloture.value = null
        if (!show) date_cloture.required = false
        if (show) date_cloture.required = true
    }

    toggleSuspension(){
        const panelSuspension = document.getElementById("panelSuspension")
        const isHidden = panelSuspension.classList.toggle("fr-hidden")
        const suspension_submit_wrapper = document.getElementById("suspension_submit_wrapper")
        const otherButtons = document.getElementById("otherButtons")
        suspension_submit_wrapper.classList.toggle("fr-hidden")
        otherButtons.classList.toggle("fr-hidden")
        // Change le texte et le style du bouton selon l'état
        if (isHidden) {
            this.toggleSuspensionButtonTarget.innerHTML = "Suspendre l'acte"
            this.submitActionTarget.value = "en cours d'instruction"
        } else {
            this.toggleSuspensionButtonTarget.innerHTML = "Annuler"
            this.submitActionTarget.value = "suspendu"
        }

        //hidden date choture
        this.checkDecision()
    }
    suspendSkipValidation(){
        this.submitActionTarget.value = "à suspendre"
    }

    // to delete
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
    checkDecision(){
        const selectedValue = this.decisionTarget.value;
        const date_cloture_wrapper = document.getElementById('date_cloture_wrapper');
        const date_cloture = document.getElementById('date_cloture');
        const submitAction = this.submitActionTarget
        const etat_conditions = submitAction.value === "en cours d'instruction"
        if (etat_conditions && (selectedValue === "Retour sans décision (sans suite)" || selectedValue === "Saisine a posteriori")){
            date_cloture_wrapper.classList.remove('fr-hidden');
            date_cloture.value = null;
        }else{
            date_cloture_wrapper.classList.add('fr-hidden');
            date_cloture.value = null;

        }
    }

    clotureSkipValidation(){
        const cloture_button = document.getElementById('cloture_button');
        const validation_button = document.getElementById('validation_button');
        const save_button = document.getElementById('save_button');
        const date_cloture = document.getElementById('date_cloture');
        if (date_cloture.value){
            cloture_button.classList.remove('fr-hidden');
            validation_button.classList.add('fr-hidden');
            save_button.classList.add('fr-hidden');
        }else{
            cloture_button.classList.add('fr-hidden');
            validation_button.classList.remove('fr-hidden');
            save_button.classList.remove('fr-hidden');
        }
    }

    validateYears() {
        const anneeSelect = document.getElementById('annee')
        const dateChorusInput = document.getElementById('date_chorus')
        const alert = document.getElementById('alert-date-chorus')

        if (!anneeSelect || !dateChorusInput) return

        const selectedYear = parseInt(anneeSelect.value)
        const dateChorusValue = dateChorusInput.value

        if (!selectedYear || !dateChorusValue) {
            alert.classList.add('fr-hidden')
            return
        }

        // Parse la date au format français (dd/mm/yyyy)
        const dateParts = dateChorusValue.split('/')
        if (dateParts.length !== 3) {
            alert.classList.add('fr-hidden')
            return
        }

        const dateChorusYear = parseInt(dateParts[2])

        if (selectedYear !== dateChorusYear) {
            alert.classList.remove('fr-hidden')
        } else {
            alert.classList.add('fr-hidden')
        }
    }

}
