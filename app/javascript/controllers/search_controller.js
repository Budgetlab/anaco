import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static get targets() {
        return ['button', 'commentaireCourt', 'nav'];
    }

    connect() {
    }

    collapse(event){
        const searchTerm = event.target.value
        if (searchTerm.length >= 1) {
            this.buttonTarget.setAttribute("aria-expanded", "true");
        }else{
            this.buttonTarget.setAttribute("aria-expanded", "false");
        }
    }
}