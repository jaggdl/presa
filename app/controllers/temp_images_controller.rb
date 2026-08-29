# frozen_string_literal: true

# Serves short-lived images uploaded through a tool call back to a service (or
# caller) that needs the bytes by URL. Deliberately unauthenticated: the
# filename is an unguessable random token and the file only lives for a few
# minutes before a background job deletes it, so there is no long-lived secret
# to protect.
class TempImagesController < ActionController::Base
  # Downloads provably large, single-use blobs: no cookies, no CSRF.
  protect_from_forgery with: :null_session

  def show
    bytes = TempImageStore.read(params[:filename])
    raise ActiveRecord::RecordNotFound if bytes.nil?

    TempImageStore.sweep!
    send_data bytes, type: TempImageStore.mime_for(params[:filename]), disposition: :inline
  end
end
