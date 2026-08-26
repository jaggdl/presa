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
  # authorization requests against this workspace. Stored only as a digest,
  # exposed raw exactly once at creation.
  def share_code
    return @share_code if defined?(@share_code)

    if share_code_digest.blank?
      @share_code = reset_share_code!
    else
      @share_code = nil
    end
  end

  # Rotate the share code, invalidating any pending authorization requests.
  # Returns the new raw code; the caller must show it to the user once.
  def reset_share_code!
    raw = SecureRandom.base58(32)
    update!(share_code_digest: ApiToken.digest(raw))
    bot_authorizations.pending.each(&:expire!)
    @share_code = raw
  end

  def valid_share_code?(raw)
    share_code_digest.present? && !raw.blank? && ApiToken.digest(raw) == share_code_digest
  end
end
