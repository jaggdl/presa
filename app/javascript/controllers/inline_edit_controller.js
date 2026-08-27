import { Controller } from "@hotwired/stimulus"

// Inline-edits a single field (name or description) on the workspace show page.
// The value text sits in normal flow and always defines the row height; the edit
// form is rendered absolutely on top of it while editing, so toggling never
// shifts layout. The pencil button is hidden while editing. The form auto-saves
// on blur and does nothing if the value is unchanged; Escape cancels.
export default class extends Controller {
  static targets = ["value", "form", "field", "button"]

  edit() {
    this.originalValue = String(this.fieldTarget.value || "").trim()
    this.buttonTarget.classList.add("hidden")
    this.valueTarget.style.visibility = "hidden"
    this.formTarget.classList.remove("hidden")
    const field = this.fieldTarget
    field.disabled = false
    field.focus()
    if (field.select) field.select()
  }

  cancel() {
    this.buttonTarget.classList.remove("hidden")
    this.valueTarget.style.visibility = ""
    this.formTarget.classList.add("hidden")
  }

  // Autosave when the field loses focus. If focus moved to another control
  // inside this block (e.g. the pencil button), cancel instead. No-op when the
  // value didn't actually change.
  save(event) {
    if (event.relatedTarget && this.element.contains(event.relatedTarget)) {
      this.cancel()
      return
    }
    if (String(this.fieldTarget.value || "").trim() === this.originalValue) {
      this.cancel()
      return
    }
    this.formTarget.requestSubmit()
  }
}