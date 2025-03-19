import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        // Limiter les pièces jointes aux images uniquement
        document.addEventListener("trix-file-accept", this.validateFileType);
    }


    validateFileType(event) {
        // Vérifier si le fichier est une image
        if (!event.file.type.match(/^image\//)) {
            // Si ce n'est pas une image, annuler l'événement
            event.preventDefault();
            alert("Seules les images sont autorisées dans ce champ");
        }
    }

}