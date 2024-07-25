import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static get targets() {
        return ['commentaireLong','commentaireCourt', 'nav'];
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
}
