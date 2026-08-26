import { Controller } from "@hotwired/stimulus"

// Toggles visibility of revoked clients, driven by a `data-show-revoked`
// boolean on the controller element. Rows and icons use CSS group toggles
// keyed off that value, so no per-target logic is needed here.
export default class extends Controller {
  static values = { showRevoked: Boolean }

  toggle() {
    this.showRevokedValue = !this.showRevokedValue
  }
}