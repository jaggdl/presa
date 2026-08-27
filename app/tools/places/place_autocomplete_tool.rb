# frozen_string_literal: true

module Places
  # Autocomplete (New): returns place and query predictions matching a text
  # input as the user types. A session token (optional) groups calls into a
  # session for billing purposes. Field masking controls the returned (and
  # billed) suggestion fields.
  class PlaceAutocompleteTool < Base
    description "Get place and query predictions as the user types (autocomplete), optionally scoped to a region"
    kind "place_autocomplete"

    DEFAULT_FIELDS = "suggestions.placePrediction.place,suggestions.placePrediction.placeId,suggestions.placePrediction.text.text,suggestions.placePrediction.structuredFormat.mainText.text,suggestions.placePrediction.structuredFormat.secondaryText.text,suggestions.placePrediction.types"

    arguments do
      required(:input).filled(:string).description("The text to search on (place names, addresses, plus codes), e.g. 'pizza in New York'")
      optional(:included_primary_types).array(:string).description("Up to five primary place types from Table A to restrict to, e.g. ['restaurant']")
      optional(:included_region_codes).array(:string).description("Up to 15 two-character ccTLD country codes to restrict results to, e.g. ['us']")
      optional(:include_query_predictions).filled(:bool).description("When true, also return query predictions (default false)")
      optional(:input_offset).filled(:integer, gteq?: 0).description("Zero-based character offset of the cursor within input; influences predictions")
      optional(:origin_latitude).filled(:float).description("Origin latitude to calculate straight-line distance to predictions")
      optional(:origin_longitude).filled(:float).description("Origin longitude to calculate straight-line distance to predictions")
      optional(:bias_latitude).filled(:float).description("Center latitude of a circle to bias results toward")
      optional(:bias_longitude).filled(:float).description("Center longitude of a circle to bias results toward")
      optional(:bias_radius).filled(:float, gteq?: 0.0, lteq?: 50_000).description("Radius in meters of the bias circle (0 < radius <= 50000)")
      optional(:restrict_latitude).filled(:float).description("Center latitude of a circle to restrict results within")
      optional(:restrict_longitude).filled(:float).description("Center longitude of a circle to restrict results within")
      optional(:restrict_radius).filled(:float, gt?: 0.0, lteq?: 50_000).description("Radius in meters of the restriction circle")
      optional(:language_code).filled(:string).description("The preferred language (BCP-47), e.g. 'en' (default en)")
      optional(:region_code).filled(:string).description("Two-character ccTLD region code, e.g. 'us'")
      optional(:session_token).filled(:string).description("A user-generated string grouping this call into a session for billing")
      optional(:fields).filled(:string).description("Comma-separated X-Goog-FieldMask of suggestion fields, NOT prefixed (controls billing)")
    end

    def call(input:, included_primary_types: nil, included_region_codes: nil, include_query_predictions: nil,
             input_offset: nil, origin_latitude: nil, origin_longitude: nil,
             bias_latitude: nil, bias_longitude: nil, bias_radius: nil,
             restrict_latitude: nil, restrict_longitude: nil, restrict_radius: nil,
             language_code: nil, region_code: nil, session_token: nil, fields: nil)
      body = { input: input }
      body[:includedPrimaryTypes] = included_primary_types if included_primary_types.present?
      body[:includedRegionCodes] = included_region_codes if included_region_codes.present?
      body[:includeQueryPredictions] = include_query_predictions unless include_query_predictions.nil?
      body[:inputOffset] = input_offset if input_offset
      body[:origin] = { latitude: origin_latitude, longitude: origin_longitude } if origin_latitude && origin_longitude
      body[:locationBias] = circle(latitude: bias_latitude, longitude: bias_longitude, radius: bias_radius) if bias_latitude && bias_longitude && bias_radius
      body[:locationRestriction] = circle(latitude: restrict_latitude, longitude: restrict_longitude, radius: restrict_radius) if restrict_latitude && restrict_longitude && restrict_radius
      body[:languageCode] = language_code if language_code
      body[:regionCode] = region_code if region_code
      body[:sessionToken] = session_token if session_token

      places_post("places:autocomplete", fields: fields.presence || DEFAULT_FIELDS, body: body)
    end

    private

    def circle(latitude:, longitude:, radius:)
      { circle: { center: { latitude: latitude, longitude: longitude }, radius: radius } }
    end
  end
end
