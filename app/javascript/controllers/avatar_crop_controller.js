import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileInput", "image", "cropContainer", "croppedData"]

  connect() {
    this.cropper = null
  }

  loadImage(event) {
    const file = event.target.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => {
      this.imageTarget.src = e.target.result
      this.cropContainerTarget.classList.remove("hidden")
      this.initCropper()
    }
    reader.readAsDataURL(file)
  }

  initCropper() {
    // Simple crop functionality using canvas
    const img = this.imageTarget
    const canvas = document.createElement('canvas')
    const ctx = canvas.getContext('2d')

    img.onload = () => {
      // Set canvas size to 100x100
      canvas.width = 100
      canvas.height = 100

      // Calculate crop dimensions (center crop to square)
      const size = Math.min(img.naturalWidth, img.naturalHeight)
      const x = (img.naturalWidth - size) / 2
      const y = (img.naturalHeight - size) / 2

      // Draw cropped and resized image
      ctx.drawImage(img, x, y, size, size, 0, 0, 100, 100)

      // Convert to blob
      canvas.toBlob((blob) => {
        const reader = new FileReader()
        reader.onloadend = () => {
          this.croppedDataTarget.value = reader.result
        }
        reader.readAsDataURL(blob)
      }, 'image/jpeg', 0.9)
    }
  }

  disconnect() {
    if (this.cropper) {
      this.cropper.destroy()
    }
  }
}
