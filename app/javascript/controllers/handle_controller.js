import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "error"]

  connect() {
    console.log("Handle controller connected")
    this.errorTimeout = null
  }

  validate(event) {
    const input = event.target
    const value = input.value
    
    // Remove any non-latin characters, numbers, and underscores
    // Also convert to lowercase
    const cleaned = value.toLowerCase().replace(/[^a-z0-9_]/g, '')
    
    if (value !== cleaned) {
      input.value = cleaned
      this.showError()
      
      // Clear any existing timeout
      if (this.errorTimeout) {
        clearTimeout(this.errorTimeout)
      }
      
      // Hide error message after 3 seconds
      this.errorTimeout = setTimeout(() => {
        this.hideError()
      }, 3000)
    }
  }

  showError() {
    if (this.hasErrorTarget) {
      this.errorTarget.classList.remove("hidden")
    }
  }

  hideError() {
    if (this.hasErrorTarget) {
      this.errorTarget.classList.add("hidden")
    }
  }
  
  disconnect() {
    if (this.errorTimeout) {
      clearTimeout(this.errorTimeout)
    }
  }
}
