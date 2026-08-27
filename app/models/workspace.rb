class Workspace < ApplicationRecord
  include WorkspaceStats
  include WorkspaceTools

  belongs_to :user
  has_many :api_tokens, dependent: :destroy
  has_many :tool_invocations, through: :api_tokens
  has_many :workspace_services, dependent: :destroy
  has_many :services, through: :workspace_services
  has_many :bot_authorizations, dependent: :destroy

  validates :name, presence: true

  # A resettable secret the owner shares with an agent so it can file bot
  # authorization requests against this workspace. The raw value is stored so
  # the owner can view and copy it from the UI; a digest is also kept to compare
  # cheaply and to guard the stored value.
  def share_code
    if read_attribute(:share_code).blank?
      reset_share_code!
    else
      read_attribute(:share_code)
    end
  end

  # Rotate the share code, invalidating any pending authorization requests.
  # Returns the new raw code.
  def reset_share_code!
    raw = SecureRandom.base58(32)
    update!(share_code: raw, share_code_digest: ApiToken.digest(raw))
    bot_authorizations.pending.each(&:expire!)
    raw
  end

  def valid_share_code?(raw)
    share_code.present? && !raw.blank? && ActiveSupport::SecurityUtils.secure_compare(share_code, raw)
  end

  # Find the single workspace whose share code matches the given raw value. A
  # share code maps 1:1 to a workspace, so we can identify the workspace from
  # the code alone. Returns nil when no match.
  def self.find_by_share_code(raw)
    return nil if raw.blank?

    where.not(share_code: nil).find { |w| w.valid_share_code?(raw) }
  end
end
