import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu", "button"]

  toggle(event) {
    console.log("Toggle clicked")
    event.stopPropagation()
    this.menuTarget.classList.toggle("hidden")
  }

  hide(event) {
    if (!this.element.contains(event.target)) {
      this.menuTarget.classList.add("hidden")
    }
  }

  connect() {
    console.log("Dropdown controller connected")
    this.boundHide = this.hide.bind(this)
    document.addEventListener("click", this.boundHide)
  }

  disconnect() {
    document.removeEventListener("click", this.boundHide)
  }
}
