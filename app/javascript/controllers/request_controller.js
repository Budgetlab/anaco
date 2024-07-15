import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static get targets() {
        return ["form"];
    }

    connect() {
    }

    checkTag(event){
        event.preventDefault();
        let button = event.currentTarget;
        let checkbox = button.querySelector('input[type="checkbox"]');
        checkbox.checked = !checkbox.checked;
        this.formTarget.requestSubmit();
    }
    addTagSelected(event){
        event.preventDefault();
        const selectedValue = event.currentTarget.value;
        const selectedName = event.currentTarget.options[event.currentTarget.selectedIndex].text;
        // Ajouter les tags si n'existe pas déjà
        const tag = `<li data-action="click->request#removeTagSelected" data-value="${selectedValue}"><button class="fr-tag fr-tag--dismiss" aria-label="Retirer">${selectedName}</button></li>`;
        const nomTag = event.currentTarget.getAttribute("data-tag");
        const fieldTag = document.getElementById(nomTag);
        let checkbox = fieldTag.querySelector('input[type="checkbox"][value="' + selectedValue + '"]');
        if (checkbox.checked == false){
            checkbox.checked = !checkbox.checked;
            fieldTag.insertAdjacentHTML("beforeend", tag);
        }
        // Réinitialiser le champ select
        const selectElement = event.currentTarget.closest(".fr-select-group").querySelector(".fr-select");
        selectElement.selectedIndex = 0;
        // submit form
        this.formTarget.requestSubmit();
    }
    removeTagSelected(event){
        event.preventDefault();
        const selectedValue = event.currentTarget.getAttribute("data-value");
        let checkbox = event.currentTarget.parentNode.querySelector('input[type="checkbox"][value="' + selectedValue + '"]');
        if (checkbox.checked){
            checkbox.checked = !checkbox.checked;
        }
        this.formTarget.requestSubmit()
    }

    toggleFilter(event){
        event.preventDefault();
        const button = event.currentTarget
        const nomTag = button.getAttribute("data-tag");
        const fieldTag = document.getElementById(nomTag);
        fieldTag.classList.toggle("fr-hidden");
        const text = button.getAttribute("data-text");
        const text_inner = button.textContent;
        button.setAttribute("data-text", text_inner);
        button.textContent = text;

    }

}