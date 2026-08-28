# frozen_string_literal: true

module Places
  # Nearby Search (New): finds places around a given location (a circle defined
  # by center latitude/longitude and a radius in meters). Field masking controls
  # the returned (and billed) place fields.
  class NearbySearchTool < Base
    description "Search for places near a location by radius and optional place types"

    DEFAULT_FIELDS = "places.id,places.displayName,places.formattedAddress,places.location,places.types,places.rating,places.priceLevel"

    RANK_PREFERENCES = %w[POPULARITY DISTANCE].freeze

    arguments do
      required(:latitude).filled(:float).description("Center latitude of the search circle (e.g. 37.7937)")
      required(:longitude).filled(:float).description("Center longitude of the search circle (e.g. -122.3965)")
      required(:radius).filled(:integer, gt?: 0, lteq?: 50_000).description("Radius of the search circle in meters (0 < radius <= 50000)")
      optional(:included_types).array(:string).description("Place types (from Table A) to include, e.g. ['restaurant', 'cafe']")
      optional(:excluded_types).array(:string).description("Place types (from Table A) to exclude")
      optional(:included_primary_types).array(:string).description("Primary place types (from Table A) to include")
      optional(:excluded_primary_types).array(:string).description("Primary place types (from Table A) to exclude")
      optional(:max_result_count).filled(:integer, gteq?: 1, lteq?: 20).description("Maximum number of results to return (default 20)")
      optional(:rank_preference).filled(:string, included_in?: RANK_PREFERENCES).description("Result ranking: POPULARITY (default) or DISTANCE")
      optional(:language_code).filled(:string).description("The language in which to return results, e.g. 'en'")
      optional(:region_code).filled(:string).description("Two-character CLDR country code used to format the response, e.g. 'US'")
      optional(:fields).filled(:string).description("Comma-separated X-Goog-FieldMask of place fields, each prefixed with 'places.' (controls billing)")
    end

    def call(latitude:, longitude:, radius:, included_types: nil, excluded_types: nil,
             included_primary_types: nil, excluded_primary_types: nil, max_result_count: nil,
             rank_preference: nil, language_code: nil, region_code: nil, fields: nil)
      body = {
        locationRestriction: {
          circle: { center: { latitude: latitude, longitude: longitude }, radius: radius }
        }
      }
      body[:includedTypes] = included_types if included_types.present?
      body[:excludedTypes] = excluded_types if excluded_types.present?
      body[:includedPrimaryTypes] = included_primary_types if included_primary_types.present?
      body[:excludedPrimaryTypes] = excluded_primary_types if excluded_primary_types.present?
      body[:maxResultCount] = max_result_count if max_result_count
      body[:rankPreference] = rank_preference if rank_preference
      body[:languageCode] = language_code if language_code
      body[:regionCode] = region_code if region_code

      places_post("places:searchNearby", fields: fields.presence || DEFAULT_FIELDS, body: body)
    end
  end
end
