import { Controller } from "@hotwired/stimulus"

// Renders a flash message as a floating toast at the top-right edge. Auto-dismisses
// after `timeout` ms (default 6s), halting while the pointer is over it so long
// messages can be read, and removes itself on the close button / autoclose.
export default class extends Controller {
  static values = { timeout: { type: Number, default: 6000 } }

  connect() {
    this.removing = false
    this.startTimer()
  }

  disconnect() {
    this.stopTimer()
  }

  startTimer() {
    this.stopTimer()
    this.timer = setTimeout(() => this.close(), this.timeoutValue)
  }

  stopTimer() {
    if (this.timer) {
      clearTimeout(this.timer)
      this.timer = null
    }
  }

  pause() {
    this.stopTimer()
  }

  resume() {
    this.startTimer()
  }

  close() {
    if (this.removing) return
    this.removing = true
    this.stopTimer()
    this.element.classList.add("opacity-0", "-translate-y-2", "pointer-events-none")
    this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
  }
}