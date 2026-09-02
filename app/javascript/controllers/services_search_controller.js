import { Controller } from "@hotwired/stimulus"

// Submits the services index search form (debounced) as the user types. The
// server filters and paginates the kind cards, replying with a turbo stream
// that replaces the grid.
export default class extends Controller {
  static targets = ["input"]

  submit() {
    clearTimeout(this.timer)
    this.timer = setTimeout(() => this.element.requestSubmit(), 200)
  }
}