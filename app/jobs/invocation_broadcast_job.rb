# Announces a newly-recorded tool invocation to any open workspace pages via
# Turbo Streams over ActionCable. Runs in the background so MCP tool execution
# isn't blocked by the broadcast.
class InvocationBroadcastJob < ApplicationJob
  include Turbo::Streams::ActionHelper

  queue_as :default

  def perform(invocation_id)
    invocation = ToolInvocation.find_by(id: invocation_id)
    return if invocation.nil?

    html = ApplicationController.render(
      partial: "tool_invocations/invocation",
      locals: { invocation: invocation },
      formats: [ :html ]
    )

    payload = [
      turbo_stream_action_tag("prepend", target: "tool-invocations", template: html),
      turbo_stream_action_tag("remove", target: "tool-invocations-empty")
    ].join

    ActionCable.server.broadcast(
      "invocations_#{invocation.workspace.id}",
      payload
    )
  end
end
