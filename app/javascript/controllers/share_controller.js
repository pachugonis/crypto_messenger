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
        this.showNotification(this.getTranslation('link_copied'))
      }
    } catch (error) {
      console.error("Error generating share link:", error)
    }
  }

  async generateFolder() {
    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        }
      })
      
      // Let Turbo handle the stream response
      if (response.ok) {
        const stream = await response.text()
        const div = document.createElement('div')
        div.innerHTML = stream
        
        const streamElements = div.querySelectorAll('turbo-stream')
        streamElements.forEach(element => {
          document.body.appendChild(element)
        })
      }
    } catch (error) {
      console.error("Error generating folder share link:", error)
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

  getTranslation(key) {
    const translations = {
      'link_copied': document.documentElement.lang === 'ru' ? 'Ссылка скопирована!' : 'Link copied!'
    }
    return translations[key] || key
  }
}
