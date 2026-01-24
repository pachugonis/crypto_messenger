import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "previewImage"]

  previewImage(event) {
    const file = event.target.files[0]
    
    if (!file) return
    
    // Check file size (1MB = 1048576 bytes)
    if (file.size > 1048576) {
      alert("Размер изображения не должен превышать 1 МБ")
      event.target.value = ""
      return
    }
    
    // Check file type
    const validTypes = ['image/png', 'image/jpeg', 'image/jpg', 'image/gif', 'image/webp']
    if (!validTypes.includes(file.type)) {
      alert("Поддерживаются только изображения (PNG, JPEG, GIF, WebP)")
      event.target.value = ""
      return
    }
    
    // Show preview
    const reader = new FileReader()
    reader.onload = (e) => {
      this.previewImageTarget.src = e.target.result
      this.previewTarget.classList.remove("hidden")
    }
    reader.readAsDataURL(file)
  }

  removeImage(event) {
    event.preventDefault()
    this.inputTarget.value = ""
    this.previewImageTarget.src = ""
    this.previewTarget.classList.add("hidden")
  }
}
