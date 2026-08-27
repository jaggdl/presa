# frozen_string_literal: true

module Bots
  # Device-authorization flow for agents: an agent presents a pre-shared share
  # code to file a request; the workspace owner approves/rejects it from the
  # browser; the agent redeems the approval code it's given for a real API
  # token. Agent-facing endpoints (create, token) respond in plain text;
  # browser-facing ones (show, approve, reject) are owner-gated.
  class AuthorizationsController < ApplicationController
    # Agent-facing endpoints are called before any session exists.
    allow_unauthenticated_access only: [ :authorize, :token ]
    skip_forgery_protection only: %i[ authorize token ]

    # POST /bots/authorize
    # Body: { "share_code": ..., "name": ..., "justification": ... }
    # Creates a pending authorization for the workspace identified by the share
    # code and returns { request_id, authorize_url }.
    def authorize
      @workspace = Workspace.find_by_share_code(body[:share_code])
      return render plain: "Unauthorized.\n", status: :unauthorized unless @workspace

      return render plain: "Name required.\n", status: :unprocessable_entity if name.blank?

      authorization = BotAuthorization.initiate!(workspace: @workspace, name: name, justification: justification)
      render json: {
        request_id: authorization.request_token,
        authorize_url: bots_authorization_url(authorization.request_token)
      }
    end

    # GET /bots/authorizations/:request_token — browser page describing the
    # pending request so the owner can approve or reject it.
    def show
      @authorization = BotAuthorization.find_by(request_token: params[:request_token])
      return render plain: "Request not found.\n", status: :not_found unless @authorization

      render :show
    end

    # POST /bots/authorizations/:request_token/approve — owner approves; returns
    # the one-time code for the user to relay to the agent.
    def approve
      @authorization = authorize_owned_request
      return render plain: "Not authorized.\n", status: :not_found unless @authorization

      # If already approved with a live code (e.g. a Turbo double-submit), just
      # re-show the code rather than losing it behind a redirect.
      @code = @authorization.approve!
      @code ||= @authorization.reissue_code! if @authorization.approved? && !@authorization.consumed?
      return redirect_to bots_authorization_path(@authorization.request_token) unless @code

      render :approve
    end

    # POST /bots/authorizations/:request_token/reject — owner rejects.
    def reject
      @authorization = authorize_owned_request
      return render plain: "Not authorized.\n", status: :not_found unless @authorization

      @authorization.reject!

      redirect_to bots_authorization_path(@authorization.request_token)
    end

    # POST /bots/authorizations/:request_token/token — agent redeems its code
    # for a raw API token (single-use). Rate-limited per IP to blunt brute-force
    # of the (now higher-entropy) code.
    def token
      return render plain: "Rate limited.\n", status: :too_many_requests unless rate_limit_allowed?

      authorization = BotAuthorization.find_by(request_token: params[:request_token])
      raw = authorization&.redeem!(body[:code])
      return render plain: "Invalid or expired code.\n", status: :unauthorized unless raw

      render json: { token: raw }
    end

    private

    TOKEN_REDEEM_LIMIT = 10
    TOKEN_REDEEM_WINDOW = 5.minutes

    # Fixed-window per-IP throttle for the token-redeem endpoint. Falls open
    # (allows) if the cache store can't count, so availability is never
    # sacrificed -- entropy is the primary defense, this is defense-in-depth.
    def rate_limit_allowed?
      key = "bots:token-redeem:#{request.remote_ip}"
      count = Rails.cache.increment(key, 1, expires_in: TOKEN_REDEEM_WINDOW)
      count.nil? || count <= TOKEN_REDEEM_LIMIT
    end

    def name
      body[:name]
    end

    def justification
      body[:justification]
    end

    def body
      @body ||= params.permit(:share_code, :name, :justification, :code).to_unsafe_h.symbolize_keys
    end

    def authorize_owned_request
      return nil unless authenticated? && Current.user

      authorization = BotAuthorization.find_by(request_token: params[:request_token])
      return nil unless authorization&.owner?(Current.user)

      authorization
    end
  end
end
