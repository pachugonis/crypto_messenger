import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  closeOnBackdrop(event) {
    if (event.target === this.element) {
      this.close()
    }
  }

  closeOnEscape(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  close() {
    this.element.remove()
  }
}
