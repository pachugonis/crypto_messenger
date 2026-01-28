import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["track"]
  
  connect() {
    console.log("Ticker controller connected")
    this.setupTicker()
  }
  
  setupTicker() {
    const track = this.trackTarget
    const items = Array.from(track.children)
    
    console.log(`Found ${items.length} items to animate`)
    
    // Clone all items for seamless loop
    items.forEach(item => {
      const clone = item.cloneNode(true)
      track.appendChild(clone)
    })
    
    console.log(`Total items after cloning: ${track.children.length}`)
    
    // Calculate animation duration based on content width
    const trackWidth = track.scrollWidth
    const duration = trackWidth / 50 // 50 pixels per second
    
    console.log(`Track width: ${trackWidth}px, Duration: ${duration}s`)
    
    // Apply animation
    track.style.animationDuration = `${duration}s`
    track.classList.add('ticker-animate')
    
    console.log("Animation started")
  }
}
