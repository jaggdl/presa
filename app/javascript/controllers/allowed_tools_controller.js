import { Controller } from "@hotwired/stimulus"

// Controls the per-tool checkboxes in the workspace_service "allowed tools" form.
export default class extends Controller {
  static targets = ["checkbox"]

  selectAll() {
    this.checkboxTargets.forEach((checkbox) => { checkbox.checked = true })
  }

  deselectAll() {
    this.checkboxTargets.forEach((checkbox) => { checkbox.checked = false })
  }
}