import { Controller } from "@hotwired/stimulus"

// Updates the read-only scopes note in the credential form to the selected
// provider's default scopes (embedded in each option's data-scope). Scopes are
// defined by the service, not the client, so this is informational only.
export default class extends Controller {
  static targets = ["select", "scopeNote"]

  syncScope() {
    const option = this.selectTarget.selectedOptions[0]
    if (option && option.dataset.scope) {
      this.scopeNoteTarget.textContent = option.dataset.scope
    }
  }
}