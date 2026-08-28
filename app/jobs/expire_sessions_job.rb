# Deletes expired session rows so the sessions table stays lean. Runs as a
# Solid Queue recurring task in production (see config/recurring.yml). Live
# sessions are bumped on every authenticated request; expired ones are only
# cleaned here or on their next touch (authentication concern).
class ExpireSessionsJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 1_000

  def perform
    loop do
      ids = Session.where("expires_at IS NOT NULL AND expires_at <= ?", Time.current)
                   .limit(BATCH_SIZE)
                   .pluck(:id)
      break if ids.empty?

      Session.where(id: ids).delete_all
    end
  end
end
