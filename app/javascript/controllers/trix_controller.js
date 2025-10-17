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
        // vérifier poids des fichiers
        if (event.file.size > 1024 * 1024 * 1){
            event.preventDefault();
            alert("La taille maximale par fichier autorisée est de 1 Mo.");
        }
    }

}