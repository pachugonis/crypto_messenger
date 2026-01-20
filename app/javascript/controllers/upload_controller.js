import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  submit() {
    if (this.inputTarget.files.length > 0) {
      this.element.requestSubmit()
    }
  }
}
