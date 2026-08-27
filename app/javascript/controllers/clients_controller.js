import { Controller } from "@hotwired/stimulus"

// Toggles visibility of revoked clients and manages the "connect client" modal.
// The modal shows two ways to connect: via MCP or via the agent skill.
// Visibility of revoked rows/icons is driven by the `data-clients-show-revoked-value`
// boolean on the controller element via Tailwind `group-data-[...]` variants, so
// only the modal, the panel switch, and the boolean flip live here.
export default class extends Controller {
  static targets = ["dialog", "mcpPanel", "skillPanel"]
  static values = { showRevoked: Boolean, panel: String }

  connect() {
    this.show("mcp")
  }

  toggle() {
    this.showRevokedValue = !this.showRevokedValue
  }

  // Open the modal, defaulting to the MCP panel.
  open() {
    this.dialogTarget.showModal()
    this.show("mcp")
  }

  // Open the modal directly on the skill panel.
  openSkill() {
    this.dialogTarget.showModal()
    this.show("skill")
  }

  // Switch which connect panel (mcp | skill) is visible. Updates both panels'
  // MCP/Skill tab buttons' selected styling and toggles panel visibility.
  select(event) {
    const key = event.currentTarget.dataset.panel
    this.show(key)
  }

  show(key) {
    this.mcpPanelTarget.classList.toggle("hidden", key !== "mcp")
    this.skillPanelTarget.classList.toggle("hidden", key !== "skill")
    this.panelValue = key

    this.element.querySelectorAll("[data-panel]").forEach((btn) => {
      const on = btn.dataset.panel === key
      btn.classList.toggle("border-blue-500", on)
      btn.classList.toggle("text-white", on)
      btn.classList.toggle("bg-blue-500/20", on)
      btn.classList.toggle("border-zinc-700", !on)
      btn.classList.toggle("text-zinc-400", !on)
      btn.disabled = on
    })
  }

  close() {
    this.dialogTarget.close()
  }

  // Close the modal when the user clicks on the backdrop (outside the panel).
  backdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}