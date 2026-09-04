import { Controller } from "@hotwired/stimulus"

// The OpenAPI service credential-type selector. The options come from the
// spec's security schemes; when the user switches type, the hidden credential
// name (header/query/cookie name) and the explanatory hint update to match.
// When the spec declares an OAuth scheme, one option is "oauth": switching to
// it reveals the OAuth connect region (client selector / connect buttons) and
// hides the manual credential value field, and vice versa.
export default class extends Controller {
  static targets = ["type", "name", "hint", "oauthRegion"]
  static values = { nameByType: Object }

  sync() {
    const type = this.typeTarget.value
    this.nameTarget.value = this.nameByTypeValue[type] || ""
    const option = this.typeTarget.selectedOptions[0]
    this.hintTarget.textContent = option ? option.textContent : ""
    if (this.hasOauthRegionTarget) {
      this.oauthRegionTarget.hidden = type !== "oauth"
    }
  }
}
