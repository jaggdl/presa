import { Controller } from "@hotwired/stimulus"

// The OpenAPI service credential-type selector. The options come from the
// spec's security schemes; when the user switches type, the hidden credential
// name (header/query/cookie name) and the explanatory hint update to match.
// When the spec declares an OAuth scheme, one option is "oauth": switching to
// it reveals the OAuth connect region (client selector / connect buttons) and
// hides the manual credential value field, and vice versa.
export default class extends Controller {
  static targets = ["type", "name", "hint", "oauthRegion", "manualRegion"]
  static values = { nameByType: Object, dance: Boolean }

  sync() {
    const type = this.typeTarget.value
    this.nameTarget.value = this.nameByTypeValue[type] || ""
    const option = this.typeTarget.selectedOptions[0]
    this.hintTarget.textContent = option ? option.textContent : ""
    this.applyRegions(type === "oauth")
  }

  applyRegions(oauth) {
    if (this.hasOauthRegionTarget) this.oauthRegionTarget.hidden = !oauth
    if (this.hasManualRegionTarget) this.manualRegionTarget.hidden = oauth

    // On a brand-new service the submit flow differs by method: OAuth bounces
    // through "Continue to sign in", a manual method saves the service
    // directly. Only toggle those actions while that choice is live (i.e. the
    // new-service dance); an editing page always saves.
    if (!this.danceValue) return
    const form = this.element.closest("form")
    if (!form) return
    const oauthActions = form.querySelector("[data-openapi-cred-oauth-actions]")
    const manualActions = form.querySelector("[data-openapi-cred-manual-actions]")
    if (oauthActions) oauthActions.hidden = !oauth
    if (manualActions) manualActions.hidden = oauth
    if (oauth) {
      form.setAttribute("data-turbo", "false")
    } else {
      form.removeAttribute("data-turbo")
    }
  }
}
