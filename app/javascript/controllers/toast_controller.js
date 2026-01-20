import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 3000 } }

  connect() {
    setTimeout(() => {
      this.element.classList.add("opacity-0", "transition-opacity")
      setTimeout(() => this.element.remove(), 300)
    }, this.delayValue)
  }
}
