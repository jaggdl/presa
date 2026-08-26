import { Controller } from "@hotwired/stimulus"

// Switches between installation-instruction tabs by toggling a "selected"
// class on tab buttons and showing the matching panel.
export default class extends Controller {
  static targets = ["tab", "panel"]

  select(event) {
    const key = event.currentTarget.dataset.tabsLabel

    this.tabTargets.forEach((tab) => {
      const isSelected = tab.dataset.tabsLabel === key
      tab.classList.toggle("border-blue-500", isSelected)
      tab.classList.toggle("text-white", isSelected)
      tab.classList.toggle("bg-blue-500/20", isSelected)
      tab.classList.toggle("border-zinc-700", !isSelected)
      tab.classList.toggle("text-zinc-400", !isSelected)
    })

    this.panelTargets.forEach((panel) => {
      panel.classList.toggle("hidden", panel.dataset.tabsPanel !== key)
    })
  }
}