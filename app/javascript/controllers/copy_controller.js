import { Controller } from "@hotwired/stimulus"

// Copy-to-clipboard button. Reads the text from `value` on click, writes it to
// the clipboard, and briefly swaps the label to "Copied". Falls back to a
// hidden-textarea/execCommand approach when the async Clipboard API is
// unavailable (e.g. non-secure contexts), and shows "Failed" only if both fail.
export default class extends Controller {
  static values = { value: String }

  async copy() {
    let copied = false
    try {
      if (navigator.clipboard && window.isSecureContext) {
        await navigator.clipboard.writeText(this.valueValue)
        copied = true
      }
    } catch {
      copied = false
    }

    if (!copied) {
      copied = this.fallback(this.valueValue)
    }

    this.flash(copied ? "Copied" : "Failed")
  }

  // Legacy fallback: select a temporary hidden textarea holding the value and
  // fire the browser's "copy" command.
  fallback(text) {
    try {
      const textarea = document.createElement("textarea")
      textarea.value = text
      textarea.setAttribute("readonly", "")
      textarea.style.position = "fixed"
      textarea.style.opacity = "0"
      document.body.appendChild(textarea)
      textarea.select()
      textarea.setSelectionRange(0, textarea.value.length)
      const copied = document.execCommand("copy")
      textarea.remove()
      return copied
    } catch {
      return false
    }
  }

  flash(label) {
    this.element.textContent = label
    setTimeout(() => { if (this.element.isConnected) this.element.textContent = "Copy" }, 1500)
  }
}