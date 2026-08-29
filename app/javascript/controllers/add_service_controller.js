import { Controller } from "@hotwired/stimulus"

// Manages the "Add service" modal that lists the available services for a
// workspace. The modal is a native <dialog>; open/close lives here, and the
// search input filters the list rows.
export default class extends Controller {
  static targets = ["dialog", "input", "row"]

  open() {
    this.dialogTarget.showModal()
    this.inputTarget.value = ""
    this.filter("")
  }

  close() {
    this.dialogTarget.close()
  }

  // Close the modal when the user clicks on the backdrop (outside the panel).
  backdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  // Filter the service rows by the search term against name and kind.
  filter(event) {
    const term = (event === "" ? "" : event.currentTarget?.value ?? "").trim().toLowerCase()
    this.rowTargets.forEach((row) => {
      const haystack = row.dataset.search.toLowerCase()
      row.classList.toggle("hidden", !haystack.includes(term))
    })
  }
}