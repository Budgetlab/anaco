import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
    return ['form'];
  }
  connect() {

  }
  submitFilter(){
    this.formTarget.requestSubmit()
  }

}