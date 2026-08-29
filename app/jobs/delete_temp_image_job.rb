# frozen_string_literal: true

# Deletes a stored temp image once it is no longer needed. Enqueued (and
# deferred a minute) right after a tool serves an uploaded image, so a slow
# downstream fetch still completes before the file is removed.
class DeleteTempImageJob < ApplicationJob
  queue_as :default

  def perform(filename)
    TempImageStore.delete(filename)
  end
end
