import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content"]

  connect() {
    // Add escape key listener
    this.boundEscapeHandler = this.closeOnEscape.bind(this)
    document.addEventListener("keydown", this.boundEscapeHandler)
  }

  disconnect() {
    // Remove escape key listener
    document.removeEventListener("keydown", this.boundEscapeHandler)
  }

  stopPropagation(event) {
    event.stopPropagation()
  }

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
