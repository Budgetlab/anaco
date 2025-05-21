import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="form-submit"
export default class extends Controller {
    static targets = ["submitButton", "fieldRequire", "submitAction", "form", "message", "totalMontant"]

    connect() {
        if (this.hasSubmitButtonTarget && this.submitButtonTarget.dataset.conditionsMet != undefined) {
            this.checkValidation()
        } else if (this.hasSubmitButtonTarget) {
            this.checkSubmission();
        }

        this.setNombreInput();

        if (this.hasTotalMontantTarget){
            this.updateTotal()
        }
    }

    // pour check soumission à la validation
    checkValidation() {
        const allFieldsFilled = this.fieldRequireTargets.every(field => field.value.trim() !== "")
        const conditionsMet = this.submitButtonTarget.dataset.conditionsMet === "true"
        console.log(this.fieldRequireTargets)
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

    keepCurrentState(event) {
        this.submitActionTarget.value = "en cours d'instruction"
    }

    setInstruction(event) {
        this.submitActionTarget.value = "en cours d'instruction"
    }

    confirmValidation(event) {
        this.submitActionTarget.value = "en attente de validation Chorus"
    }
    confirmCloture(event) {
        this.submitActionTarget.value = "clôturé"
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
        event.preventDefault();
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
        this.formTarget.submit();
    }

    changeTextToFloat2(event) {
        event.preventDefault();
        const fields = document.querySelectorAll("[data-acte-form-number-field]");
        fields.forEach(field => {
            const parsedValue = this.numberFormat(field.value);
            if (!isNaN(parsedValue)) {
                field.value = parsedValue;
            }
        })
        this.formTarget.submit();
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

    changeNumber2(event) {
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

    }

    toggleMessage() {
        const radioNon = document.getElementById('radio-false')
        if (radioNon && this.hasMessageTarget) {
            this.messageTarget.style.display = radioNon.checked ? '' : 'none'
        }
    }

    checkChorusNumberExistence(event){
        const numero = event.target.value;
        const acteId = event.target.dataset.acteId || ""
        console.log(acteId)
        const message = document.getElementById('message-chorus-number-existence')
        const url = this.data.get("checkchorusurl")

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

    updateTotal() {
        console.log("update total")
        // Récupérer tous les champs de montant
        const montantFields = document.querySelectorAll('input[id="montant"]')

        // Calculer la somme
        let total = 0
        montantFields.forEach(field => {
            // Convertir en nombre et ajouter au total (en gérant les valeurs vides ou non numériques)
            const value = parseFloat(field.value.replace(/\s/g, '').replace(',', '.')) || 0
            total += value
        })

        // Afficher le total formaté
        this.totalMontantTarget.textContent = total.toLocaleString('fr-FR')
    }
}
