import { Controller } from "@hotwired/stimulus"

// Toggles visibility of revoked clients and manages the "connect client" modal.
// Visibility of revoked rows/icons is driven by the `data-clients-show-revoked-value`
// boolean on the controller element via Tailwind `group-data-[...]` variants, so
// only the modal and the boolean flip live here.
export default class extends Controller {
  static targets = ["dialog"]
  static values = { showRevoked: Boolean }

  toggle() {
    this.showRevokedValue = !this.showRevokedValue
  }

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  // Close the modal when the user clicks on the backdrop (outside the panel).
  backdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}