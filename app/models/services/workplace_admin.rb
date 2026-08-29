# frozen_string_literal: true

module Services
  # A service that exposes the team's workspaces as MCP tools, letting a bot
  # read and manage a chosen workspace (its name/description, linked services,
  # allowed tools, and tool-invocation history) through the same models and
  # guards the web UI uses.
  #
  # Unlike HTTP/OAuth services, it holds no credentials: its only config is the
  # set of workspace IDs it is allowed to manage, picked in the service form so
  # the granted scope is explicit. All tools are scoped to the service owner's
  # team workspaces, so a Workplace Admin service can never touch another team's data.
  class WorkplaceAdmin < Service
    kind :workplace_admin
    icon "workplace_admin.png"
    display_name "Workplace Admin"
    category :built_in

    config_field :workspace_ids, array: true

    validate :at_least_one_workspace

    # The workspaces this service manages, resolved from the configured IDs and
    # always scoped to the owning team. Unknown/foreign IDs are silently dropped.
    def managed_workspaces
      return Workspace.none unless team

      ids = Array(config[:workspace_ids]).map(&:to_i).reject(&:zero?).uniq
      team.workspaces.where(id: ids).order(:name)
    end

    # Whether this service may manage the given workspace (same owning team and
    # in the configured set).
    def manages_workspace?(workspace)
      return false if workspace.blank? || team.nil?

      workspace.team_id == team.id && Array(config[:workspace_ids]).map(&:to_i).include?(workspace.id)
    end

    # Looks up a workspace by id among the managed set, or nil.
    def find_managed_workspace(id)
      managed_workspaces.find_by(id: id)
    end

    private

    def at_least_one_workspace
      return if Array(config[:workspace_ids]).map(&:to_i).reject(&:zero?).any?

      errors.add(:config, "select at least one workspace to manage")
    end
  end
end
