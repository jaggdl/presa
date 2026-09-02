import { Controller } from "@hotwired/stimulus"

// The OpenAPI step-2 configure form. Manages "+ Add method" extra credential
// rows.
export default class extends Controller {
  static targets = ["extraAuth", "extraAuthRow"]

  addMethod() {
    const row = document.createElement("div")
    row.className = "flex items-center gap-2"
    row.dataset.openapiStep2Target = "extraAuthRow"
    row.innerHTML = `
      <input name="integration[extra_credentials][][name]" type="text" placeholder="Header name, e.g. X-Api-Key"
             autocomplete="off"
             class="flex-1 rounded-md border border-zinc-700 focus:outline-blue-600 px-2 py-1.5 bg-zinc-900 text-xs placeholder-zinc-500">
      <select name="integration[extra_credentials][][in]"
              class="rounded-md border border-zinc-700 focus:outline-blue-600 px-2 py-1.5 bg-zinc-900 text-xs">
        <option value="header">header</option>
        <option value="query">query</option>
        <option value="cookie">cookie</option>
      </select>
      <button type="button" data-action="openapi-step2#removeMethod" aria-label="Remove"
              class="text-zinc-500 hover:text-red-400 transition">×</button>`
    this.extraAuthTarget.appendChild(row)
  }

  removeMethod(event) {
    event.currentTarget.closest("[data-openapi-step2-target='extraAuthRow']").remove()
  }
}