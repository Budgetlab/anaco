import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static get targets() {
  return ['controleur',"avis",
  ];
  }
  connect() {

  }

  filterAvis(){
    const avis = [this.avisTargets[0].checked, this.avisTargets[1].checked,this.avisTargets[2].checked]
  }

}
function getSelectedValues(event) {
        return [...event.target.selectedOptions].map(option => option.value)
    }