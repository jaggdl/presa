import { Controller } from "@hotwired/stimulus"

// The "Add OpenAPI integration" dialog shell. Data attributes come from the
// shared dialog partial (dialog target, backdrop action); this controller also
// swaps the spec input's placeholder when the source (URL vs raw) changes.
export default class extends Controller {
  static targets = ["dialog", "panel", "source", "spec"]

  open() {
    this.dialogTarget.showModal()
    this.syncPlaceholder()
  }

  close() {
    this.dialogTarget.close()
  }

  backdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  syncPlaceholder() {
    if (!this.hasSpecTarget) return
    const isUrl = this.sourceTarget?.value === "url"
    this.specTarget.placeholder = isUrl
      ? "https://api.example.com/openapi.json"
      : "Paste raw JSON/YAML content"
    this.specTarget.focus()
  }
}