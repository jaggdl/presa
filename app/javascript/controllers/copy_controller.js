import { Controller } from "@hotwired/stimulus"

// Exposes a copy-to-clipboard button. Reads the text from `value` (a URL) and
// writes it to the clipboard, then briefly swaps the label to "Copied".
export default class extends Controller {
  static values = { value: String }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.valueValue)
      this.element.textContent = "Copied"
    } catch {
      this.element.textContent = "Failed"
    }
    setTimeout(() => { if (this.element.isConnected) this.element.textContent = "Copy" }, 1500)
  }
}