# frozen_string_literal: true

# Aggregates workspace usage stats for dashboard/index listings: how many
# API tokens (clients) a workspace has and how many tool invocations occurred
# recently. Keeps the query logic in the model so controllers can stay thin.
module WorkspaceStats
  extend ActiveSupport::Concern

  # Number of API tokens (clients) linked to this workspace.
  def api_token_count
    api_tokens.size
  end

  # Number of tool invocations recorded for this workspace since `since`.
  def invocation_count(since: 24.hours.ago)
    tool_invocations.where("tool_invocations.created_at >= ?", since).count
  end
end
