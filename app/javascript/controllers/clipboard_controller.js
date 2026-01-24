import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]
  static values = {
    text: String
  }

  connect() {
    console.log('[Clipboard] Controller connected')
    console.log('[Clipboard] Text value:', this.textValue)
  }

  copy(event) {
    event.preventDefault()
    
    console.log('[Clipboard] Copy button clicked')
    console.log('[Clipboard] Text value:', this.textValue)
    
    // Decode HTML entities
    const textarea = document.createElement('textarea')
    textarea.innerHTML = this.textValue
    const text = textarea.value
    
    console.log('[Clipboard] Decoded text:', text)
    
    navigator.clipboard.writeText(text).then(() => {
      console.log('[Clipboard] Copy successful')
      // Show success message
      const button = event.currentTarget
      const originalText = button.innerHTML
      
      button.innerHTML = `
        <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"/>
        </svg>
        Скопировано!
      `
      button.classList.add("btn-success")
      button.classList.remove("btn-secondary")
      
      setTimeout(() => {
        button.innerHTML = originalText
        button.classList.remove("btn-success")
        button.classList.add("btn-secondary")
      }, 2000)
    }).catch((err) => {
      console.error('[Clipboard] Failed to copy:', err)
      alert('Не удалось скопировать коды')
    })
  }
}
