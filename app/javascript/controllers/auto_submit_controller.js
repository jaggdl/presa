import { Controller } from "@hotwired/stimulus"

// Submits the enclosing form when a control changes (used for settings toggles
// that should persist immediately).
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
