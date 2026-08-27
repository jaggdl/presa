import { Controller } from "@hotwired/stimulus"

// Toggles visibility of the "create a new OAuth client" fields based on the
// selected client choice in the new-service form. When the user picks
// "Create a new client…" (value "new"), reveal the nested client_id/secret
// inputs; otherwise hide them.
export default class extends Controller {
  static targets = ["choose", "new"]

  onChange() {
    const show = this.chooseTarget.value === "new"
    this.newTarget.classList.toggle("hidden", !show)
  }
}