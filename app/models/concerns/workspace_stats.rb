# frozen_string_literal: true

# Aggregates workspace usage stats for dashboard/index listings: how many
# API tokens (clients) a workspace has and how many tool invocations occurred
# recently. Keeps the query logic in the model so controllers can stay thin.
module WorkspaceStats
  extend ActiveSupport::Concern

  # Number of active (non-revoked, non-expired) API tokens (clients) linked to
  # this workspace.
  def api_token_count
    api_tokens.active.size
  end

  # Number of tool invocations recorded for this workspace since `since`.
  # Uses the count batch-loaded via `with_invocation_counts` when present,
  # otherwise issues a query for this workspace alone.
  def invocation_count(since: 24.hours.ago)
    return @invocation_count if @invocation_count

    tool_invocations.where("tool_invocations.created_at >= ?", since).count
  end

  class_methods do
    # Decorates each workspace in `relation` with its invocation count since
    # `since`, using a single grouped query instead of one per workspace.
    # `invocation_count` on the returned records then avoids further queries.
    def with_invocation_counts(relation, since: 24.hours.ago)
      workspaces = relation.to_a
      ids = workspaces.map(&:id)
      return workspaces if ids.empty?

      counts = ToolInvocation
        .joins(:api_token)
        .where(api_tokens: { workspace_id: ids })
        .where("tool_invocations.created_at >= ?", since)
        .group(:workspace_id)
        .count

      workspaces.each do |workspace|
        workspace.instance_variable_set(:@invocation_count, counts.fetch(workspace.id, 0))
      end
      workspaces
    end
  end
end
