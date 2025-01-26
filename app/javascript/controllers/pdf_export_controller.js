import { Controller } from "@hotwired/stimulus"
import { jsPDF } from 'jspdf';
import html2canvas from 'html2canvas';
import { Canvg } from 'canvg';

export default class extends Controller {
    static targets = ["button"]
    connect() {

    }
    export(){
        this._toggleButtonState(true);
        // Attendre un court instant pour laisser le DOM se stabiliser
        setTimeout(() => {
            this._prepareForExport();
        }, 50);
    }
    _prepareForExport() {
        const printElements = document.querySelectorAll('.print');
        const noprintElements = document.querySelectorAll('.no-print');
        this._toggleVisibility(printElements, false);
        this._toggleVisibility(noprintElements, true);

        const element = document.getElementById('containPDF');
        element.classList.add('fr-container');
        this._hideIconsOnLinks()
        this._captureAndExport(element, printElements, noprintElements);

    }

    _captureAndExport(element, printElements, noprintElements) {
        html2canvas(element, { useCORS: true, scale: 2 }).then((canvas) => {
            this.generatePDF(canvas);
            this._resetExportState(printElements,noprintElements, element);
        });
    }

    // Méthode privée pour désactiver le bouton le temps de l'export et modifier le texte
    _toggleButtonState(disable) {
        this.buttonTarget.disabled = disable;
        this.buttonTarget.textContent = disable
            ? "Génération du PDF en cours (cela peut prendre quelques secondes)..."
            : "Exporter au format PDF";
    }

    // Méthode privée pour afficher ou cacher les éléments
    _toggleVisibility(elements, hidden) {
        elements.forEach(el => el.classList.toggle('fr-hidden', hidden));
    }
    // Méthode privée pour réinitialiser l'état après l'export
    _resetExportState(printElements, noprintElements, element) {
        this._toggleButtonState(false);
        this._toggleVisibility(printElements, true);
        this._toggleVisibility(noprintElements, false);
        element.classList.remove('fr-container');
        this._showIconsOnLinks()
    }
    generatePDF(canvas) {
        const title = this.buttonTarget.dataset.pdfExportTitle || 'Export.pdf'
        const imgData = canvas.toDataURL('image/png');
        // Crée un nouveau document PDF au format A4 en mode portrait ('p')
        const pdf = new jsPDF('p', 'mm', 'a4');
        const imgProps = pdf.getImageProperties(imgData);
        const pdfWidth = pdf.internal.pageSize.getWidth();
        const pdfHeight = (imgProps.height * pdfWidth) / imgProps.width;

        let heightLeft = pdfHeight;
        let position = 0;
        let pageHeight = pdf.internal.pageSize.getHeight();

        while (heightLeft >= 0) {
            pdf.addImage(imgData, 'PNG', 0, position, pdfWidth, pdfHeight);
            heightLeft -= pageHeight;
            if (heightLeft > 0) {
                pdf.addPage();
                position -= pageHeight;
            }
        }
        pdf.save(title);
    }

    _convertMasksToCanvas() {
        const elements = document.querySelectorAll('[class^="fr-icon"]');
        const promises = [];

        elements.forEach((el) => {
            const style = window.getComputedStyle(el, '::before');
            const maskImage = style.getPropertyValue('-webkit-mask-image') || style.getPropertyValue('mask-image');
            const urlMatch = maskImage.match(/url\("(.*?)"\)/);

            if (urlMatch && urlMatch[1]) {
                const svgUrl = urlMatch[1];
                promises.push(
                    fetch(svgUrl)
                        .then(response => response.text())
                        .then(svgText => {
                            const canvas = document.createElement('canvas');
                            const context = canvas.getContext('2d');
                            const v = Canvg.fromString(context, svgText);
                            v.start();
                            el.replaceWith(canvas);
                        })
                );
            }
        });

        return Promise.all(promises);
    }

    _hideIconsOnLinks() {
        const links = document.querySelectorAll('a[target="_blank"]');
        console.log(links);
        links.forEach((link) => {
            // Ajouter la classe 'hide-icons' pour masquer les icônes
            link.classList.add('hide-icons');
        });
    }
    _showIconsOnLinks() {
        const links = document.querySelectorAll('a[target="_blank"]');
        links.forEach((link) => {
            // Ajouter la classe 'hide-icons' pour masquer les icônes
            link.classList.remove('hide-icons');
        });
    }
}