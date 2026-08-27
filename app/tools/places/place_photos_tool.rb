# frozen_string_literal: true

module Places
  # Place Photos (New): returns photo metadata (including a usable photoUri)
  # for a photo resource name obtained from a Place Details or Text Search
  # response's `photos[]` array. Photo names expire, so always fetch them fresh
  # from a recent search/details call.
  class PlacePhotosTool < Base
    description "Get photo details and a URL for a place photo (drived from a photo name in a search or details response)"
    kind "place_photos"

    arguments do
      required(:photo_name).filled(:string).description("The photo resource name from a place's photos[] array, e.g. 'places/PLACE_ID/photos/PHOTO_RESOURCE'")
      optional(:max_width_px).filled(:integer, gteq?: 1, lteq?: 4800).description("Maximum width of the image in pixels; must specify a width or a height (or both)")
      optional(:max_height_px).filled(:integer, gteq?: 1, lteq?: 4800).description("Maximum height of the image in pixels; must specify a width or a height (or both)")
    end

    def call(photo_name:, max_width_px: nil, max_height_px: nil)
      params = { key: api_key, skipHttpRedirect: true }
      params[:maxWidthPx] = max_width_px if max_width_px
      params[:maxHeightPx] = max_height_px if max_height_px

      conn.get("#{photo_name}/media", params).body
    end
  end
end
