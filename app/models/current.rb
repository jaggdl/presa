class Current < ActiveSupport::CurrentAttributes
  attribute :session, :workspace, :api_token, :team
  delegate :user, to: :session, allow_nil: true
end
