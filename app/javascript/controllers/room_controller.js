import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static values = { id: Number }
  
  connect() {
    this.consumer = createConsumer()
    this.typingTimeout = null
    this.typingUsers = new Map()
    
    this.subscription = this.consumer.subscriptions.create(
      { channel: "RoomChannel", room_id: this.idValue },
      {
        received: (data) => this.handleReceived(data),
        connected: () => console.log("Connected to room", this.idValue),
        disconnected: () => console.log("Disconnected from room", this.idValue)
      }
    )
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
    if (this.consumer) {
      this.consumer.disconnect()
    }
  }

  handleReceived(data) {
    if (data.type === "typing") {
      this.showTyping(data.user_id, data.username)
    } else if (data.type === "stop_typing") {
      this.hideTyping(data.user_id)
    }
  }

  typing() {
    if (this.typingTimeout) {
      clearTimeout(this.typingTimeout)
    } else {
      this.subscription.perform("typing")
    }
    
    this.typingTimeout = setTimeout(() => {
      this.subscription.perform("stop_typing")
      this.typingTimeout = null
    }, 2000)
  }

  showTyping(userId, username) {
    this.typingUsers.set(userId, username)
    this.updateTypingIndicator()
  }

  hideTyping(userId) {
    this.typingUsers.delete(userId)
    this.updateTypingIndicator()
  }

  updateTypingIndicator() {
    const indicator = document.getElementById("typing-indicator")
    const textEl = indicator?.querySelector("[data-typing-target='text']")
    
    if (!indicator || !textEl) return
    
    if (this.typingUsers.size > 0) {
      const names = Array.from(this.typingUsers.values())
      if (names.length === 1) {
        textEl.textContent = `${names[0]} печатает`
      } else {
        textEl.textContent = `${names.join(", ")} печатают`
      }
      indicator.classList.remove("hidden")
    } else {
      indicator.classList.add("hidden")
    }
  }
}
