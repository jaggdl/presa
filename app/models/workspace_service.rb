class WorkspaceService < ApplicationRecord
  ALLOW_ALL = "*"

  belongs_to :workspace
  belongs_to :service

  serialize :allowed_tools, coder: JSON

  validate :service_belongs_to_same_user

  # The tool identifiers this workspace may use for this service. `["*"]` means
  # every tool exposed by the service is allowed. Unset/legacy rows read as
  # `["*"]`; an explicit empty array means no tools are allowed.
  def allowed_tools
    value = read_attribute(:allowed_tools)
    value.nil? ? [ ALLOW_ALL ] : Array(value).map(&:to_s)
  end

  def allowed_tools=(value)
    arr = Array(value).map(&:to_s).reject(&:blank?)
    super(arr.include?(ALLOW_ALL) ? [ ALLOW_ALL ] : arr)
  end

  def all_tools_allowed?
    allowed_tools.include?(ALLOW_ALL)
  end

  def tool_allowed?(tool_key)
    all_tools_allowed? || allowed_tools.include?(tool_key.to_s)
  end

  # Number of the service's exposed tools that this workspace may use. `["*"]`
  # counts every exposed tool.
  def enabled_tool_count(tools)
    if all_tools_allowed?
      tools.count
    else
      allowed = allowed_tools
      tools.count { |tool| allowed.include?(tool.tool_key) }
    end
  end

  private

  def service_belongs_to_same_user
    errors.add(:service, "must belong to the same user as the workspace") if workspace.user_id != service.user_id
  end
end
