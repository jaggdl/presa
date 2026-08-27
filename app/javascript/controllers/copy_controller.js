import { Controller } from "@hotwired/stimulus"

// Copy-to-clipboard button. Reads the text from `value`, or from a `source`
// target element, on click and copies it.
//
// The async Clipboard API is preferred: it works on secure contexts (localhost
// and https) including inside native `<dialog>` modals. The fallback performs a
// synchronous copy of a real DOM selection via `execCommand("copy")`, which
// still works on plain-HTTP pages where the Clipboard API is unavailable.
export default class extends Controller {
  static targets = ["source", "idle", "done"]
  static values = { value: String }

  async copy() {
    const text = this.sourceTarget?.textContent?.trimEnd() ?? this.valueValue

    if (navigator.clipboard && window.isSecureContext) {
      try {
        await navigator.clipboard.writeText(text)
        this.flash(true)
        return
      } catch {
        // fall through to the fallback below
      }
    }

    this.flash(this.copySelection(text))
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

  // Swaps the copy icon for a check icon (a "done" target) or, in its absence,
  // swaps the button label text to signal success/failure, resetting shortly
  // after.
  flash(copied) {
    if (copied) clearTimeout(this._resetTimer)

    if (copied && this.hasIdleTarget && this.hasDoneTarget) {
      this.idleTarget.classList.add("hidden")
      this.doneTarget.classList.remove("hidden")
      this._resetTimer = setTimeout(() => {
        this.idleTarget.classList.remove("hidden")
        this.doneTarget.classList.add("hidden")
      }, 1500)
    } else {
      this.element.textContent = copied ? "Copied" : "Failed"
      if (copied) {
        this._resetTimer = setTimeout(() => { this.element.textContent = "Copy" }, 1500)
      }
    }
  }
}