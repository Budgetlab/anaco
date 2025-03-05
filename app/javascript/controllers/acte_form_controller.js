import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form-submit"
export default class extends Controller {
    static targets = ["submitButton", "fieldRequire","submitAction"]
    connect() {
        if (this.submitButtonTarget.dataset.conditionsMet != undefined){
            this.checkValidation()
        } else if (this.hasSubmitButtonTarget){
            this.checkSubmission();
        }
    }

    // pour check soumission à la validation
    checkValidation() {
        const allFieldsFilled = this.fieldRequireTargets.every(field => field.value.trim() !== "")
        const conditionsMet = this.submitButtonTarget.dataset.conditionsMet === "true"

        this.submitButtonTarget.disabled = !(allFieldsFilled && conditionsMet)
    }

    // pour check validation finale
    checkSubmission(){
        const allFieldsFilled = this.fieldRequireTargets.every(field => field.value.trim() !== "")
        this.submitButtonTarget.disabled = !allFieldsFilled
    }

    setValidation(event) {
        this.submitActionTarget.value = "attente validation"
    }

    keepCurrentState(event) {
        this.submitActionTarget.value = "instruction"
    }
    setInstruction(event) {
        this.submitActionTarget.value = "instruction"
    }

    confirmValidation(event){
        this.submitActionTarget.value = "cloture"
    }
}
