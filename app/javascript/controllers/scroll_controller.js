import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { bottom: { type: Boolean, default: true } }

  connect() {
    if (this.bottomValue) {
      this.scrollToBottom()
    }
    
    this.observer = new MutationObserver(() => {
      if (this.isNearBottom()) {
        this.scrollToBottom()
      }
    })
    
    this.observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }

  isNearBottom() {
    const threshold = 100
    return this.element.scrollHeight - this.element.scrollTop - this.element.clientHeight < threshold
  }
}
