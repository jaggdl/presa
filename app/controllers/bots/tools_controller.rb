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
    before_action :authenticate_token!, except: %i[ skill client installer ]

    # GET /bots/SKILL.md — the agent skills file describing how to authenticate
    # and use the tools API. Served unauthenticated so agents can fetch it to
    # learn the flow. Only describes the generic API surface, never any
    # workspace-specific tools, services, or workflows.
    def skill
      render "bots/tools/skill", layout: nil, content_type: "text/markdown", formats: [ :md ]
    end

    # GET /bots/client/presa — the bundled client script that the skill
    # installs. Served unauthenticated alongside SKILL.md so agents can fetch
    # it as part of setting up the skill. Base URL is baked in, so the client
    # never needs it (or any tool URL / token) typed by hand.
    def client
      render "bots/tools/presa", layout: nil, formats: [ :sh ], content_type: "text/x-sh"
    end

    # GET /bots/client/install.sh — idempotent installer that puts the presa
    # client on PATH. Also unauthenticated so the skill flow can pull it.
    # Embeds the fully-rendered client so the installer is self-contained.
    def installer
      @client_script = render_to_string("bots/tools/presa", formats: [ :sh ])
      render "bots/tools/client_install", layout: nil, formats: [ :sh ], content_type: "text/x-sh"
    end

    # GET /bots/workspace
    def workspace
      render plain: Current.workspace.workspace_context_text
    end

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
