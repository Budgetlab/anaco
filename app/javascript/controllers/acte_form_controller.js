import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form-submit"
export default class extends Controller {
    static targets = ["submitAction"]
    connect() {
    }

    setValidation(event) {
        this.submitActionTarget.value = "validation"
    }

    keepCurrentState(event) {
        console.log("keep")
        this.submitActionTarget.value = "keep"
    }
}
