import { Controller } from "@hotwired/stimulus"

// Toggles visibility of an "Add service" button vs the available-services list.
export default class extends Controller {
  static targets = ["button", "list"]

  toggle() {
    const showing = !this.listTarget.classList.contains("hidden")
    this.listTarget.classList.toggle("hidden", showing)
    this.buttonTarget.classList.toggle("hidden", !showing)
  }
}
