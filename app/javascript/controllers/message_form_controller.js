import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "submit"]

  connect() {
    this.resize()
  }

  resize() {
    const input = this.inputTarget
    input.style.height = "auto"
    input.style.height = Math.min(input.scrollHeight, 128) + "px"
  }

  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      if (this.inputTarget.value.trim()) {
        this.element.requestSubmit()
      }
    }
  }

  reset() {
    this.inputTarget.value = ""
    this.resize()
    this.inputTarget.focus()
    
    // Clear image preview if upload controller exists
    const uploadController = this.application.getControllerForElementAndIdentifier(this.element, "upload")
    if (uploadController) {
      uploadController.removeImage(new Event('click'))
    }
    
    // Scroll to bottom after message sent
    const container = document.getElementById("messages-container")
    if (container) {
      setTimeout(() => {
        container.scrollTop = container.scrollHeight
      }, 100)
    }
  }
}
