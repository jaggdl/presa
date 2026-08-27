import { Controller } from "@hotwired/stimulus"

// Manages the OAuth client selector in the new-service form. Choosing
// "Create a new client…" opens a modal with the credential form; on success a
// turbo stream swaps in the new client option (already selected) and closes
// the modal.
export default class extends Controller {
  static targets = ["choose", "dialog"]

  onChange() {
    if (this.chooseTarget.value === "new") {
      this.openDialog()
      this.chooseTarget.value = ""
    } else {
      this.closeDialog()
    }
  }

  openDialog() {
    this.dialogTarget.showModal()
  }

  closeDialog() {
    if (this.dialogTarget.open) this.dialogTarget.close()
  }

  // Close the modal when the user clicks on the backdrop (outside the panel).
  backdrop(event) {
    if (event.target === this.dialogTarget) this.closeDialog()
  }
}