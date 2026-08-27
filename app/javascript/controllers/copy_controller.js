import { Controller } from "@hotwired/stimulus"

// Copy-to-clipboard button. Reads the text from `value` on click and copies it.
//
// The primary mechanism is a synchronous copy of a real DOM selection
// (`execCommand("copy")`), which performs an actual clipboard write in every
// browser and context (including HTTP). The async Clipboard API can silently
// resolve without writing, and priming it can swallow a subsequent sync write,
// so we only use it as a fallback when the sync path is blocked.
export default class extends Controller {
  static values = { value: String }

  async copy() {
    const text = this.valueValue

    if (this.copySelection(text)) {
      this.flash("Copied")
      return
    }

    if (navigator.clipboard && window.isSecureContext) {
      try {
        await navigator.clipboard.writeText(text)
        this.flash("Copied")
        return
      } catch {
        // fall through to failure feedback
      }
    }

    this.flash("Failed")
  }

  // Selects a temporary hidden textarea holding the value and fires the
  // browser's "copy" command on that real selection.
  copySelection(text) {
    const textarea = document.createElement("textarea")
    textarea.value = text
    textarea.setAttribute("readonly", "")
    textarea.setAttribute("aria-hidden", "true")
    textarea.style.position = "fixed"
    textarea.style.top = "0"
    textarea.style.left = "0"
    textarea.style.opacity = "0"
    document.body.appendChild(textarea)
    textarea.focus()
    textarea.select()
    textarea.setSelectionRange(0, text.length)

    let ok = false
    try {
      ok = document.execCommand("copy")
    } catch {
      ok = false
    }
    textarea.remove()
    return ok
  }

  flash(label) {
    this.element.textContent = label
    setTimeout(() => { if (this.element.isConnected) this.element.textContent = "Copy" }, 1500)
  }
}