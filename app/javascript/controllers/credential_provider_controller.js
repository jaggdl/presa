import { Controller } from "@hotwired/stimulus"

// Syncs the scopes field in the new-credential form to the selected provider's
// default scopes (embedded in each option's data-scope). Lets the user switch
// between OAuth providers (e.g. Google, Strava) on a single form.
export default class extends Controller {
  static targets = ["select", "scopes"]

  syncScope() {
    const option = this.selectTarget.selectedOptions[0]
    if (option && option.dataset.scope) {
      this.scopesTarget.value = option.dataset.scope
    }
  }
}