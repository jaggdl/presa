# frozen_string_literal: true

module GoogleCalendar
  # Abstract base for all Google Calendar tools. Not exposed directly. HTTP
  # transport and OAuth bearer-token injection live on the service (composed
  # via `Oauth::Client`); this base keeps only the Calendar-specific request
  # shaping — URL-encoding calendar ids, mapping times to the API's
  # dateTime/date shape, and normalizing attendees.
  class Base < ApplicationTool
    service_kind :calendar
    abstract_tool true

    private

    # PATH for a calendar resource, URL-encoding each segment so calendar IDs
    # like "user@gmail.com" or "en.usa#holiday@group.v.calendar.google.com"
    # survive the request. Relative to the service's API base
    # (`.../calendar/v3`): a leading slash would make Faraday drop the base
    # path and hit the host root.
    def calendar_path(calendar_id, *segments)
      encoded = [ ERB::Util.url_encode(calendar_id.to_s), *segments.map { |s| ERB::Util.url_encode(s.to_s) } ]
      "calendars/#{encoded.join("/")}"
    end

    # GET against the Calendar API, returning the parsed JSON body.
    def calendar_get(path, params: {})
      service.client.get(path, params: params)
    end

    # POST against the Calendar API, sending `body` as JSON. Returns the parsed
    # JSON body.
    def calendar_post(path, body:)
      service.client.post(path, body: body)
    end

    # PATCH against the Calendar API, sending `body` as JSON. Returns the
    # parsed JSON body.
    def calendar_patch(path, body:)
      service.client.patch(path, body: body)
    end

    # DELETE against the Calendar API.
    def calendar_delete(path)
      service.client.delete(path)
    end

    # Maps a user-supplied start/end value to the Calendar API's event time
    # shape: an RFC3339 datetime becomes { dateTime }, a bare YYYY-MM-DD date
    # becomes an all-day { date }. An optional IANA timeZone is applied when
    # given.
    def date_field(value, time_zone = nil)
      field = if value.to_s.match?(/\A\d{4}-\d{2}-\d{2}\z/)
                { date: value.to_s }
      else
                { dateTime: value.to_s }
      end
      field[:timeZone] = time_zone if time_zone.present?
      field
    end

    # Normalizes an attendees argument (array of email strings and/or { email }
    # hashes) to the Calendar API's attendee objects.
    def normalize_attendees(attendees)
      attendees.map { |a| a.is_a?(Hash) ? a.transform_keys(&:to_s) : { "email" => a.to_s } }
    end
  end
end
