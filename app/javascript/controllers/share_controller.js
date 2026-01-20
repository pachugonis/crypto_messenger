import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  async generate() {
    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        }
      })
      
      const data = await response.json()
      
      if (data.url) {
        await navigator.clipboard.writeText(data.url)
        this.showNotification("Ссылка скопирована!")
      }
    } catch (error) {
      console.error("Error generating share link:", error)
    }
  }

  showNotification(message) {
    const toast = document.createElement("div")
    toast.className = "toast toast-success"
    toast.textContent = message
    document.body.appendChild(toast)
    
    setTimeout(() => {
      toast.classList.add("opacity-0", "transition-opacity")
      setTimeout(() => toast.remove(), 300)
    }, 2000)
  }
}
