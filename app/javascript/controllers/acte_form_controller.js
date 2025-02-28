import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form-submit"
export default class extends Controller {
    static targets = ["submitAction"]
    connect() {
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
