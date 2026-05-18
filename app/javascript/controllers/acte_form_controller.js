import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="form-submit"
export default class extends Controller {
    static targets = ["submitButton", "fieldRequire", "submitAction", "form", "message", "totalMontant", 'totalMontantEcheancierAE', 'totalMontantEcheancierCP', 'etatRadio', 'preRadio', 'decision', 'typeEngagement', 'montantAe', 'etatClotureRadio', "toggleSuspensionButton", "perimetreRadio", "categorieRadio", "categorieBlock", "tfOption", "dateCloture", "submitCloture", "dateSuspension", "programmationBlock", "titreRadio", "categorieT2Block", "categorieT2Radio", "natureT2Select", "natureT2Section"]
    static values = { prefixes: Object }
    connect() {

        this.setNombreInput();

        if (this.hasTotalMontantTarget) {
            this.updateTotalLignesPoste()
        }
        if (this.hasTotalMontantEcheancierAETarget) {
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
        if (this.hasPerimetreRadioTarget){
            // modal nouvel acte - choix périmètre
            this.togglePerimetre()
        }
        if (this.hasTitreRadioTarget){
            // modal nouvel acte - choix titre HT2/T2
            this.toggleTitre()
        }
        if (this.hasNatureT2SelectTarget){
            // formulaire T2 étape 1 - restaure la section nature au chargement
            this.toggleNatureT2()
        }
        this.calculateEffetEnveloppe()
    }
    setValidation(event) {
        this.submitActionTarget.value = "à valider"
    }

    confirmCloture(event) {
        this.submitActionTarget.value = "clôturé"
    }

    // fonction pour enlever les required true pour la sauvegarde
    removeRequiredAndSubmit(){
        this.element.querySelectorAll('[required]').forEach(field => {
            field.removeAttribute('required');
        });
        this.submitActionTarget.value = "en cours d'instruction"
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
        const message_tf_prefix = document.getElementById('message-chorus-tf-prefix')
        let requiredLength = 10;
        if (typeActe === "TF") {
            requiredLength = 8;
        }

        // Alerte préfixe TF
        if (message_tf_prefix) {
            message_tf_prefix.classList.toggle('fr-hidden', numero === '' || numero.toUpperCase().startsWith('TF'))
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

        // Récupérer tous les champs de montant AE
        const montantFields_ae = document.querySelectorAll('input[id="echeancier_ae"]')
        // Calculer la somme AE
        let total_ae = 0
        montantFields_ae.forEach(field => {
            // Convertir en nombre et ajouter au total (en gérant les valeurs vides ou non numériques)
            const value = this.numberFormat(field.value) || 0
            total_ae += value
        })
        // Afficher le total formaté
        this.totalMontantEcheancierAETarget.textContent = total_ae.toLocaleString('fr-FR')

        // Gérer le total CP seulement si le target existe (pas pour les recettes organisme)
        let total_cp = 0
        if (this.hasTotalMontantEcheancierCPTarget) {
            // Récupérer tous les champs de montant CP
            const montantFields_cp = document.querySelectorAll('input[id="echeancier_cp"]')
            // Calculer la somme
            montantFields_cp.forEach(field => {
                // Convertir en nombre et ajouter au total (en gérant les valeurs vides ou non numériques)
                const value = this.numberFormat(field.value) || 0
                total_cp += value
            })
            // Afficher le total formaté
            this.totalMontantEcheancierCPTarget.textContent = total_cp.toLocaleString('fr-FR')
        }

        // afficher le bloc si lignes présentes
        if (montantFields_ae.length === 0 || (montantFields_ae.length === 1 && total_cp === 0 && total_ae === 0)) { // gérer le cas ou supp unique ligne de post length == 1
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
        if (montantField_cp) {
            montantField_cp.value = null;
        }
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

    // Helpers partagés pour la visibilité des blocs conditionnels (titre × périmètre)
    _currentTitre() {
        return this.hasTitreRadioTarget
            ? (this.titreRadioTargets.find(r => r.checked)?.value || 'HT2')
            : 'HT2'
    }

    _currentPerimetre() {
        return this.hasPerimetreRadioTarget
            ? (this.perimetreRadioTargets.find(r => r.checked)?.value || 'etat')
            : 'etat'
    }

    _updateTfVisibility() {
        if (!this.hasTfOptionTarget) return
        const showTf = this._currentTitre() === 'HT2' && this._currentPerimetre() === 'etat'
        const tfRadio = document.getElementById('TF')
        if (showTf) {
            this.tfOptionTarget.classList.remove('fr-hidden')
            if (tfRadio) tfRadio.disabled = false
        } else {
            this.tfOptionTarget.classList.add('fr-hidden')
            if (tfRadio) {
                if (tfRadio.checked) {
                    tfRadio.checked = false
                    const avisRadio = document.getElementById('avis')
                    if (avisRadio) avisRadio.checked = true
                }
                tfRadio.disabled = true
            }
        }
    }

    _updateCategorieOrganismeVisibility() {
        if (!this.hasCategorieBlockTarget) return
        const showCatOrg = this._currentTitre() === 'HT2' && this._currentPerimetre() === 'organisme'
        if (showCatOrg) {
            this.categorieBlockTarget.classList.remove('fr-hidden')
        } else {
            this.categorieBlockTarget.classList.add('fr-hidden')
            if (this.hasCategorieRadioTarget) {
                this.categorieRadioTargets.forEach((el) => {
                    el.checked = false
                    el.required = false
                })
            }
        }
        if (showCatOrg && this.hasCategorieRadioTarget) {
            this.categorieRadioTargets.forEach((el) => { el.required = true })
        }
    }

    // Modal affichage choix catégorie et type d'acte selon périmètre
    togglePerimetre(event){
        this._updateCategorieOrganismeVisibility()
        this._updateTfVisibility()
    }

    // Modal affichage selon le titre choisi (HT2 / T2)
    toggleTitre(event){
        const isT2 = this._currentTitre() === 'T2'

        // Catégorie T2 : visible seulement si T2
        if (this.hasCategorieT2BlockTarget) {
            if (isT2) {
                this.categorieT2BlockTarget.classList.remove('fr-hidden')
                // Auto-sélectionner "Hors contrat" si rien n'est coché
                if (this.hasCategorieT2RadioTarget) {
                    this.categorieT2RadioTargets.forEach((el) => { el.required = true })
                    if (!this.categorieT2RadioTargets.some(r => r.checked)) {
                        const horsContrat = this.categorieT2RadioTargets.find(r => r.value === 'hors contrat')
                        if (horsContrat) horsContrat.checked = true
                    }
                }
            } else {
                this.categorieT2BlockTarget.classList.add('fr-hidden')
                // Reset large : couvre aussi le radio "contrat" disabled (pas un target)
                this.categorieT2BlockTarget.querySelectorAll('input[type="radio"]').forEach((el) => {
                    el.checked = false
                    el.required = false
                })
            }
        }

        // Catégorie organisme et TF : dépendent de titre ET périmètre
        this._updateCategorieOrganismeVisibility()
        this._updateTfVisibility()
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

    checkDateSuspension() {
        if (!this.hasDateSuspensionTarget) return

        const input = this.dateSuspensionTarget
        const errorEl = document.getElementById('error-date-suspension')
        if (!errorEl) return

        const parseDate = (str) => {
            if (!str) return null
            const parts = str.split('/')
            if (parts.length !== 3) return null
            return new Date(parseInt(parts[2]), parseInt(parts[1]) - 1, parseInt(parts[0]))
        }

        const dateSuspension = parseDate(input.value)
        const minDate = parseDate(input.dataset.minDateSuspension)

        if (!input.value || !dateSuspension || !minDate) {
            errorEl.classList.add('fr-hidden')
            return
        }

        if (dateSuspension < minDate) {
            errorEl.classList.remove('fr-hidden')
        } else {
            errorEl.classList.add('fr-hidden')
        }
    }

    checkDateSuspensionFuture() {
        if (!this.hasDateSuspensionTarget) return

        const input = this.dateSuspensionTarget
        const warningEl = document.getElementById('warning-date-suspension-future')
        if (!warningEl) return

        const parseDate = (str) => {
            if (!str) return null
            const parts = str.split('/')
            if (parts.length !== 3) return null
            return new Date(parseInt(parts[2]), parseInt(parts[1]) - 1, parseInt(parts[0]))
        }

        const dateSuspension = parseDate(input.value)
        if (!dateSuspension) { warningEl.classList.add('fr-hidden'); return }

        const today = new Date()
        today.setHours(0, 0, 0, 0)

        if (dateSuspension > today) {
            warningEl.classList.remove('fr-hidden')
        } else {
            warningEl.classList.add('fr-hidden')
        }
    }

    checkDateCloture() {
        if (!this.hasDateClotureTarget) return

        const input = this.dateClotureTarget
        const errorEl = document.getElementById('delai-traitement-error')
        if (!errorEl) return

        const dateClotureStr = input.value
        const minDateStr = input.dataset.minDateCloture

        const parseDate = (str) => {
            if (!str) return null
            const parts = str.split('/')
            if (parts.length !== 3) return null
            return new Date(parseInt(parts[2]), parseInt(parts[1]) - 1, parseInt(parts[0]))
        }

        const dateCloture = parseDate(dateClotureStr)
        const minDate = parseDate(minDateStr)
        const infoEl = document.getElementById('delai-traitement-info')

        if (!dateClotureStr || !dateCloture || isNaN(dateCloture) || !minDate) {
            input.setCustomValidity('')
            errorEl.classList.add('fr-hidden')
            errorEl.textContent = ''
            if (infoEl) { infoEl.classList.add('fr-hidden'); infoEl.textContent = '' }
            return
        }

        const today = new Date()
        today.setHours(0, 0, 0, 0)

        if (dateCloture < minDate) {
            input.setCustomValidity('invalid')
            errorEl.textContent = `La date de clôture ne peut pas être antérieure au ${minDateStr}.`
            errorEl.className = 'fr-error-text'
            if (infoEl) { infoEl.classList.add('fr-hidden'); infoEl.textContent = '' }
        } else {
            input.setCustomValidity('')
            if (dateCloture > today) {
                errorEl.textContent = `La date de clôture est postérieure à la date du jour.`
                errorEl.className = 'fr-message cwarning fr-text--small'
            } else {
                errorEl.classList.add('fr-hidden')
                errorEl.textContent = ''
            }

            // Calcul du délai de traitement
            if (infoEl) {
                const dateSaisine = parseDate(input.dataset.dateSaisine)
                const typeActe = input.dataset.typeActe || ''
                let suspensions = []
                try { suspensions = JSON.parse(input.dataset.suspensions || '[]') } catch(e) {}

                const diffJours = (d1, d2) => Math.round((d1 - d2) / (1000 * 60 * 60 * 24))

                let delai
                if (!dateSaisine) {
                    delai = null
                } else if (suspensions.length === 0) {
                    delai = diffJours(dateCloture, dateSaisine)
                } else if (typeActe === 'avis') {
                    const dureeTotal = diffJours(dateCloture, dateSaisine)
                    const dureeSuspensions = suspensions.reduce((acc, s) => {
                        const ds = parseDate(s.ds)
                        const dr = parseDate(s.dr)
                        return (ds && dr) ? acc + diffJours(dr, ds) : acc
                    }, 0)
                    delai = Math.max(dureeTotal - dureeSuspensions, 0)
                } else if (typeActe === 'visa' || typeActe === 'TF') {
                    const suspsWithReprise = suspensions.filter(s => s.dr)
                    if (suspsWithReprise.length > 0) {
                        const derniere = suspsWithReprise[suspsWithReprise.length - 1]
                        const dateReprise = parseDate(derniere.dr)
                        delai = dateReprise ? diffJours(dateCloture, dateReprise) : diffJours(dateCloture, dateSaisine)
                    } else {
                        delai = diffJours(dateCloture, dateSaisine)
                    }
                } else {
                    delai = diffJours(dateCloture, dateSaisine)
                }

                if (delai !== null) {
                    infoEl.textContent = `Délai de traitement : ${delai} jour(s)`
                    infoEl.className = delai > 15
                        ? 'fr-message fr-message--warning fr-text--small'
                        : 'fr-message fr-message--info fr-text--small'
                } else {
                    infoEl.classList.add('fr-hidden')
                }
            }
        }
    }

    toggleSuspension(){
        const panelSuspension = document.getElementById("panelSuspension")
        const isHidden = panelSuspension.classList.toggle("fr-hidden")
        const suspension_submit_wrapper = document.getElementById("suspension_submit_wrapper")
        const otherButtons = document.getElementById("otherButtons")
        suspension_submit_wrapper.classList.toggle("fr-hidden")
        otherButtons.classList.toggle("fr-hidden")
        const asterix_proposition = document.getElementById("asterix_proposition")
        asterix_proposition.classList.toggle("fr-hidden")
        this.decisionTarget.removeAttribute('required');
        // Change le texte et le style du bouton selon l'état
        this.toggleSuspensionButtonTarget.innerHTML = isHidden ? "Suspendre l'instruction" : "Annuler"
        this.submitActionTarget.value = isHidden ? "en cours d'instruction" : "suspendu"
        // Si on referme le panneau → reset les champs
        if (isHidden) {
            // 1) enlever tous les required du panel
            panelSuspension.querySelectorAll('[required]').forEach(el => { el.required = false })
            this.resetSuspensionForm(panelSuspension)
            this.decisionTarget.required = true;
        }else{
            // Le panel est visible → remettre les required sur les champs de suspension nécessaires
            const dateSuspension = panelSuspension.querySelector('#date_suspension')
            const motif          = panelSuspension.querySelector('#motif')
            if (dateSuspension) dateSuspension.required = true
            if (motif)          motif.required = true
        }

        //hidden date choture
        this.checkDecision()
    }
    suspendSkipValidation(event){
        this.submitActionTarget.value = event.target.checked ? "à suspendre" : "suspendu"
    }

    resetSuspensionForm(panel) {
        // Sélectionne tous les champs input, select et textarea du panel
        const fields = panel.querySelectorAll("input, select, textarea")

        fields.forEach(field => {
            // on ne touche pas aux boutons, hidden, ou éléments de contrôle flatpickr
            if (field.type === "hidden" || field.type === "button" || field.readOnly) return

            if (field.tagName === "SELECT") {
                field.selectedIndex = 0 // remet sur le prompt
            } else {
                field.value = ""
            }

            // Si c’est un flatpickr → on réinitialise le widget
            if (field._flatpickr) {
                field._flatpickr.clear()
            }
        })
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
            this.submitActionTarget.value = "en cours d'instruction"
            cloture_button.classList.add('fr-hidden');
            validation_button.classList.remove('fr-hidden');
            save_button.classList.remove('fr-hidden');
        }
    }

    checkDateChorusFuture() {
        const dateSaisineInput = document.getElementById('date_saisine')
        const alert = document.getElementById('alert-date-saisine-future')
        if (!dateSaisineInput || !alert) return

        const parts = dateSaisineInput.value.split('/')
        if (parts.length !== 3) { dateSaisineInput.setCustomValidity(''); alert.classList.add('fr-hidden'); return }

        const dateSaisine = new Date(parseInt(parts[2]), parseInt(parts[1]) - 1, parseInt(parts[0]))
        const today = new Date()
        today.setHours(0, 0, 0, 0)

        if (dateSaisine > today) {
            dateSaisineInput.setCustomValidity('La date de saisine ne peut pas être postérieure à la date du jour.')
            alert.classList.remove('fr-hidden')
        } else {
            dateSaisineInput.setCustomValidity('')
            alert.classList.add('fr-hidden')
        }
    }

    toggleAvisProgrammation(event) {
        if (!this.hasProgrammationBlockTarget) return
        const checked = event.target.checked
        if (checked) {
            this.programmationBlockTarget.classList.remove('fr-hidden')
        } else {
            this.programmationBlockTarget.classList.add('fr-hidden')
        }
    }

    validateYears() {
        const anneeSelect = document.getElementById('annee')
        const dateSaisineInput = document.getElementById('date_saisine')
        const alert = document.getElementById('alert-date-saisine')

        if (!anneeSelect || !dateSaisineInput) return

        const selectedYear = parseInt(anneeSelect.value)
        const dateSaisineValue = dateSaisineInput.value

        if (!selectedYear || !dateSaisineValue) {
            alert.classList.add('fr-hidden')
            return
        }

        // Parse la date au format français (dd/mm/yyyy)
        const dateParts = dateSaisineValue.split('/')
        if (dateParts.length !== 3) {
            alert.classList.add('fr-hidden')
            return
        }

        const dateSaisineYear = parseInt(dateParts[2])

        if (selectedYear !== dateSaisineYear) {
            alert.classList.remove('fr-hidden')
        } else {
            alert.classList.add('fr-hidden')
        }
    }

    validateNumeroTf(event) {
        const input = event.target
        const value = input.value.trim()
        const alertPrefix = document.getElementById('numero-tf-alert-prefix')
        const alertLength = document.getElementById('numero-tf-alert-length')

        if (alertPrefix) alertPrefix.classList.toggle('fr-hidden', value === '' || value.startsWith('30'))
        if (alertLength) alertLength.classList.toggle('fr-hidden', value === '' || value.length === 10)
    }

    validateNumeroChorusTf(event) {
        const input = event.target
        const value = input.value.trim()
        const alertPrefix = document.getElementById('numero-chorus-tf-alert-prefix')
        const alertLength = document.getElementById('numero-chorus-tf-alert-length')

        if (alertPrefix) alertPrefix.classList.toggle('fr-hidden', value === '' || value.toUpperCase().startsWith('TF'))
        if (alertLength) alertLength.classList.toggle('fr-hidden', value === '' || value.length === 8)
    }

    resetIspCercle(event) {
        const cercle = event.target.dataset.ispCercle
        if (!cercle) return

        const montant    = document.getElementById(`isp_cercle${cercle}_montant`)
        const enveloppe  = document.getElementById(`isp_cercle${cercle}_enveloppe_sgg`)
        const consom     = document.getElementById(`isp_cercle${cercle}_consommation`)
        const isOui = event.target.value === 'true'
        if (montant)   montant.required   = isOui
        if (enveloppe) enveloppe.required = isOui

        if (event.target.value !== 'false') return

        const fields = [montant, enveloppe, consom]
        fields.forEach(f => { if (f) f.value = '' })

        const natures = document.getElementById(`isp_cercle${cercle}_natures_hidden`)
        if (natures) {
            natures.value = ''
            const dropdownEl = natures.closest('[data-controller~="checkbox-dropdown"]')
            if (dropdownEl) {
                dropdownEl.querySelectorAll('input[type="checkbox"]').forEach(cb => { cb.checked = false })
                const label = dropdownEl.querySelector('[data-checkbox-dropdown-target="label"]')
                if (label) label.textContent = label.dataset.placeholder
            }
        }

        const reste = document.getElementById(`isp_cercle${cercle}_reste`)
        if (reste) reste.textContent = '--€'
    }

    calculateIspReste(event) {
        const cercle = event.target.dataset.ispCercle
        if (!cercle) return

        const enveloppeFld = document.getElementById(`isp_cercle${cercle}_enveloppe_sgg`)
        const consomFld    = document.getElementById(`isp_cercle${cercle}_consommation`)
        const resteEl      = document.getElementById(`isp_cercle${cercle}_reste`)
        if (!resteEl) return

        const envVal  = enveloppeFld?.value || ''
        const consoVal = consomFld?.value   || ''

        if (!envVal && !consoVal) {
            resteEl.textContent = '--€'
            return
        }

        const env   = isNaN(this.numberFormat(envVal))  ? 0 : (this.numberFormat(envVal)  || 0)
        const conso = isNaN(this.numberFormat(consoVal)) ? 0 : (this.numberFormat(consoVal) || 0)
        const reste = env - conso
        resteEl.textContent = reste.toLocaleString('fr-FR') + ' €'
    }

    toggleNatureT2(event) {
        const NATURE_T2_SLUGS = {
            'Annexe financière':       't2-section-annexe-financiere',
            'Enveloppe limitative':    't2-section-enveloppe-limitative',
            'Fongibilité asymétrique': 't2-section-fongibilite-asymetrique',
            'ISP':                     't2-section-isp',
            'Marché':                  't2-section-marche',
            'Mesure transversale':     't2-section-mesure-transversale',
            'Référentiel':             't2-section-referentiel'
        }

        const selectedNature = this.natureT2SelectTarget.value

        this.natureT2SectionTargets.forEach(section => {
            section.classList.add('fr-hidden')
            this._disableSectionFields(section)
        })

        if (selectedNature && NATURE_T2_SLUGS[selectedNature]) {
            const targetId = NATURE_T2_SLUGS[selectedNature]
            const section = document.getElementById(targetId)
            if (section) {
                section.classList.remove('fr-hidden')
                this._enableSectionFields(section)
            }
        }

        const cfField = document.getElementById('centre_financier_code')
        if (cfField) {
            const cfRequired = selectedNature === 'Fongibilité asymétrique'
            cfField.required = cfRequired
            const cfLabel = document.querySelector('label[for="centre_financier_code"]')
            if (cfLabel) cfLabel.textContent = 'Centre financier' + (cfRequired ? '*' : '')
        }
    }

    calculateEffetEnveloppe() {
        const montantEl = document.getElementById('el_montant_ae')
        const impactEl = document.getElementById('el_impact_maximal_sans_enveloppe')
        const effetEl = document.getElementById('el_effet_enveloppe')
        if (!montantEl || !impactEl || !effetEl) return
        const montant = this.numberFormat(montantEl.value)
        const impact = this.numberFormat(impactEl.value)
        if (!impact || impact === 0 || isNaN(montant)) {
            effetEl.textContent = '--%'
            return
        }
        const effet = Math.round(montant / impact * 100)
        effetEl.textContent = effet + '%'
    }

    _disableSectionFields(section) {
        section.querySelectorAll('input, select, textarea').forEach(el => {
            el.disabled = true
            if (el.type === 'radio') el.checked = false
        })
    }

    _enableSectionFields(section) {
        section.querySelectorAll('input, select, textarea').forEach(el => {
            el.disabled = false
            if (el.type === 'radio') el.checked = el.defaultChecked
        })
    }

}
