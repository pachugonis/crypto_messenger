import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Always use dark theme
    document.documentElement.setAttribute("data-theme", "dark")
    // Clear old theme preference from localStorage
    localStorage.removeItem("theme")
  }
}
