import { Controller } from "@hotwired/stimulus"

// Makes a tool-invocation log row expandable to reveal full details (error
// message and full query/arguments).
export default class extends Controller {
  static targets = ["details"]

  toggle() {
    this.detailsTarget.classList.toggle("hidden")
  }
}
