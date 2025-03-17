import {Controller} from "@hotwired/stimulus"

// Connects to data-controller="form-submit"
export default class extends Controller {
    static targets = ["submitButton", "fieldRequire", "submitAction", "form", "message"]

    connect() {
        if (this.submitButtonTarget.dataset.conditionsMet != undefined) {
            this.checkValidation()
        } else if (this.hasSubmitButtonTarget) {
            this.checkSubmission();
        }

        this.setNombreInput();
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

    keepCurrentState(event) {
        this.submitActionTarget.value = "en cours d'instruction"
    }

    setInstruction(event) {
        this.submitActionTarget.value = "en cours d'instruction"
    }

    confirmValidation(event) {
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
            const parsedValue = this.numberFormat(field.value);
            if (!isNaN(parsedValue)) {
                field.value = parsedValue;
            }
        })
        this.formTarget.submit();
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

    }

    toggleMessage() {
        const radioNon = document.getElementById('radio-false')
        if (radioNon && this.hasMessageTarget) {
            this.messageTarget.style.display = radioNon.checked ? '' : 'none'
        }
    }
}
