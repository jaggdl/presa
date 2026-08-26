<div class="mx-auto md:w-3/4 w-full">
  <p class="text-sm text-zinc-500 mb-2">
    <%= link_to "Workspaces", workspaces_path, class: "text-blue-500 hover:underline" %>
    / <%= link_to @workspace.name.presence || "Unnamed workspace", workspace_path(@workspace), class: "text-blue-500 hover:underline" %>
  </p>

  <h1 class="font-bold text-4xl"><%= @workspace_service.name %></h1>
  <p class="text-zinc-400 mt-1">Allowed tools for this service in <strong><%= @workspace.name.presence || "this workspace" %></strong>.</p>

  <h2 class="font-bold text-2xl mt-10">Tools</h2>

  <% if @tools.any? %>
    <%= form_with model: @workspace_service, url: workspace_workspace_service_path(@workspace, @workspace_service), method: :patch, class: "contents", data: { controller: "allowed-tools" } do |form| %>
      <div class="flex flex-wrap items-center gap-3 mt-4">
        <button type="button" data-action="allowed-tools#selectAll" class="text-center rounded-md px-3.5 py-2 bg-zinc-800 hover:bg-zinc-700 border border-zinc-700 text-zinc-100 inline-block font-medium cursor-pointer">Select all</button>
        <button type="button" data-action="allowed-tools#deselectAll" class="text-center rounded-md px-3.5 py-2 bg-zinc-800 hover:bg-zinc-700 border border-zinc-700 text-zinc-100 inline-block font-medium cursor-pointer">Deselect all</button>
        <%= form.submit "Save", class: "btn-primary" %>
      </div>

      <ul class="mt-6 divide-y divide-zinc-800 border border-zinc-800 rounded-lg">
        <% @tools.each do |tool| %>
          <% key = tool_key(tool) %>
          <li class="flex items-start gap-3 p-4">
            <label class="flex items-center gap-3 cursor-pointer">
              <%= form.check_box :allowed_tools, { multiple: true, checked: @workspace_service.tool_allowed?(key), data: { allowed_tools_target: "checkbox" } }, key, nil %>
              <span>
                <code class="text-sm text-blue-500"><%= tool.tool_name %></code>
                <% if tool_description = tool.description.presence %>
                  <p class="text-sm text-zinc-400 mt-1"><%= tool_description %></p>
                <% end %>
              </span>
            </label>
          </li>
        <% end %>
      </ul>

      <div class="mt-6">
        <%= form.submit "Save", class: "btn-primary" %>
      </div>
    <% end %>
  <% else %>
    <p class="text-zinc-500 mt-4">No tools available for this service.</p>
  <% end %>

  <div class="mt-8">
    <%= link_to "Back to service", service_path(@workspace_service.service), class: "text-zinc-400 underline hover:no-underline" %>
  </div>
</div></think>

<｜DSML｜tool_calls>
<｜DSML｜invoke name="write">
<｜DSML｜parameter name="content" string="true">import { Controller } from "@hotwired/stimulus"

// Controls the per-tool checkboxes in the workspace_service "allowed tools" form.
export default class extends Controller {
  static targets = ["checkbox"]

  selectAll() {
    this.checkboxTargets.forEach((checkbox) => { checkbox.checked = true })
  }

  deselectAll() {
    this.checkboxTargets.forEach((checkbox) => { checkbox.checked = false })
  }
}