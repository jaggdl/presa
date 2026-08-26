class ApplicationController < ActionController::Base
  include Authentication
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Render times in the user's local time zone, detected from the browser and
  # stored in the `tz` cookie.
  around_action :use_browser_time_zone

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def use_browser_time_zone(&action)
    Time.use_zone(browser_time_zone, &action)
  end

  def browser_time_zone
    tz = cookies[:tz]
    return Time.zone_default&.name || "UTC" if tz.blank?

    ActiveSupport::TimeZone[tz]&.name || tz
  end
end
