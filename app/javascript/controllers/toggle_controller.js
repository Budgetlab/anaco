import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static get targets() {
        return ['commentaireLong','commentaireCourt', 'nav', 'content', 'button'];
    }
    connect() {
    }
    toggle(event) {
        const isChecked = event.target.checked;
        const blocs = document.querySelectorAll(".options");
        blocs.forEach(element => {
            element.classList.toggle("fr-hidden");
        })
    }
    afficherPlus() {
        this.commentaireLongTarget.style.display = 'inline';
        this.commentaireCourtTarget.style.display = 'none';
    }
    afficherMoins() {
        this.commentaireCourtTarget.style.display = 'inline';
        this.commentaireLongTarget.style.display = 'none';
    }

    changeNav(event){
        this.navTargets.forEach((nav) => {
            nav.setAttribute("aria-pressed", 'false');
        });
        event.currentTarget.setAttribute("aria-pressed", 'true');
    }
    changeMenuSection(event){
        const sectionId = event.target.getAttribute("data-toggle-id");
        const section = document.getElementById(sectionId);
        this.scrollTo(section);
    }

    scrollTo(section){
        if (section) {
            // Récupérer la position de la section par rapport au document
            //const offsetTop = section.offsetTop;
            const offsetTop = section.getBoundingClientRect().top + window.scrollY;
            // Faire défiler jusqu'à la position de la section
            window.scrollTo({
                top: offsetTop,
                behavior: "smooth"
            });
        }
    }

    updateAriaCurrent(event){
        const currentTarget = event.currentTarget;
        this.navTargets.forEach(nav => {
            nav.setAttribute("aria-current", nav === currentTarget ? true : false);
        });
    }

    toggleContent(event) {
        event.preventDefault();
        this.contentTarget.classList.toggle("fr-hidden")
        // Récupérer les textes personnalisés depuis les attributs data
        const textShow = this.buttonTarget.dataset.toggleTextShow || "Afficher plus";
        const textHide = this.buttonTarget.dataset.toggleTextHide || "Afficher moins";
        if (this.contentTarget.classList.contains("fr-hidden")) {
            // Quand le contenu est caché, afficher "Renseigner plus" avec l'icône "+"
            this.buttonTarget.textContent =textShow;
            this.buttonTarget.classList.remove("fr-icon-arrow-up-s-line");
            this.buttonTarget.classList.add("fr-icon-add-line");
        } else {
            // Quand le contenu est visible, afficher "Afficher moins" sans icône
            this.buttonTarget.textContent = textHide;
            this.buttonTarget.classList.remove("fr-icon-add-line");
            this.buttonTarget.classList.add("fr-icon-arrow-up-s-line");
        }
        // this.buttonTarget.textContent = this.contentTarget.classList.contains("fr-hidden") ? "Renseigner plus d'informations" : "Afficher moins"
    }


}
