# frozen_string_literal: true

module Bots
  # Plain-text, token-authenticated API for bot clients to list the tools their
  # workspace may use. Authenticates with the same opaque bearer tokens as the
  # MCP endpoint (see ApiToken and FastMcpJwtAuth), so a token issued for a
  # workspace scopes a bot to exactly the tools that workspace allows. All tool
  # text formatting lives on Workspace (#tools_list_text, #tool_detail_text).
  class ToolsController < ApplicationController
    allow_unauthenticated_access
    skip_forgery_protection
    before_action :authenticate_token!

    # GET /bots/tools
    def index
      render plain: Current.workspace.tools_list_text
    end

    # GET /bots/tools/:tool
    def show
      tool = Current.workspace.find_allowed_tool(params[:id])
      return render plain: "Tool not found.\n", status: :not_found unless tool

      render plain: Current.workspace.tool_detail_text(tool)
    end

    # POST /bots/tools/:tool/execute — runs a tool with an args JSON body.
    def execute
      render plain: Current.workspace.execute_tool_text(params[:id], request.body.read)
    rescue WorkspaceTools::UnknownTool
      render plain: "Tool not found.\n", status: :not_found
    rescue WorkspaceTools::InvalidToolBody
      render plain: "Invalid JSON body.\n", status: :bad_request
    rescue ApplicationTool::NotAllowedToolError
      render plain: "Tool not allowed in this workspace.\n", status: :forbidden
    rescue StandardError => e
      render plain: "Tool error: #{e.message}\n", status: :unprocessable_entity
    end

    private

    def authenticate_token!
      raw = request.authorization&.to_s&.delete_prefix("Bearer ")
      token = ApiToken.find_active_by_token(raw)

      unless token
        render plain: "Unauthorized.\n", status: :unauthorized
        return
      end

      Current.api_token = token
      Current.workspace = token.workspace
      Current.session = Session.new(user: token.workspace.user)
    end
  end
end
