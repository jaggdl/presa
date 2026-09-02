import { Controller } from "@hotwired/stimulus"

// The OpenAPI service credential-type selector. The options come from the
// spec's security schemes; when the user switches type, the hidden credential
// name (header/query/cookie name) and the explanatory hint update to match.
export default class extends Controller {
  static targets = ["type", "name", "hint"]
  static values = { nameByType: Object }

  sync() {
    const type = this.typeTarget.value
    this.nameTarget.value = this.nameByTypeValue[type] || ""
    const option = this.typeTarget.selectedOptions[0]
    this.hintTarget.textContent = option ? option.textContent : ""
  }
}
