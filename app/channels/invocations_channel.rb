class InvocationsChannel < ApplicationCable::Channel
  def subscribed
    @workspace = current_user.workspaces.find_by(id: params[:workspace_id])
    reject if @workspace.nil?

    stream_from "invocations_#{@workspace.id}"
  end
end