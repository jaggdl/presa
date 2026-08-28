# frozen_string_literal: true

module Places
  # Place Details (New): fetches detailed information about a single place by
  # its place ID (as returned by Text Search). Field masking controls the
  # returned (and billed) fields.
  class PlaceDetailsTool < Base
    description "Get detailed information about a place by its place ID (as returned by a search)"

    DEFAULT_FIELDS = "id,displayName,formattedAddress,location,websiteUri,types,rating,userRatingCount,priceLevel,internationalPhoneNumber,photos"

    arguments do
      required(:place_id).filled(:string).description("The place ID to look up, e.g. 'ChIJ2fzCmcW7j4AR2JzfXBBoh6E'")
      optional(:language_code).filled(:string).description("The language in which to return results, e.g. 'en' (default en)")
      optional(:region_code).filled(:string).description("Two-character CLDR/ISO-3166 region code used to format the response, e.g. 'US'")
      optional(:fields).filled(:string).description("Comma-separated X-Goog-FieldMask of place fields to return, NOT prefixed (e.g. 'id,displayName,websiteUri')")
    end

    def call(place_id:, language_code: nil, region_code: nil, fields: nil)
      params = {}
      params[:languageCode] = language_code if language_code
      params[:regionCode] = region_code if region_code

      places_get("places/#{place_id}", fields: fields.presence || DEFAULT_FIELDS, params: params)
    end
  end
end
