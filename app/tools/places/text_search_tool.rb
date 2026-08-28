# frozen_string_literal: true

module Places
  # Text Search (New): returns a set of places matching a free-text query (e.g.
  # "pizza in New York"), with optional refinement. Field masking controls the
  # returned (and billed) place fields.
  class TextSearchTool < Base
    description "Search for places by a free-text query (e.g. 'coffee near Union Square')"

    DEFAULT_FIELDS = "places.id,places.displayName,places.formattedAddress,places.location,places.types,places.rating,places.priceLevel"

    arguments do
      required(:text_query).filled(:string).description("The text string on which to search, e.g. 'pizza in New York'")
      optional(:page_size).filled(:integer, gteq?: 1, lteq?: 20).description("Number of results per page (default 20, max 20)")
      optional(:page_token).filled(:string).description("The nextPageToken from a previous response to get the next page")
      optional(:included_type).filled(:string).description("Biases results to a place type from the Table A list, e.g. 'restaurant' or 'pharmacy' (one type only)")
      optional(:language_code).filled(:string).description("The language in which to return results, e.g. 'en' (default en)")
      optional(:region_code).filled(:string).description("Two-character CLDR/ISO-3166 region code used to format the response, e.g. 'US'")
      optional(:open_now).filled(:bool).description("When true, return only places that are open at the time of the query")
      optional(:min_rating).filled(:float).description("Only return places with an average user rating at least this high (0.0-5.0)")
      optional(:rank_preference).filled(:string, included_in?: %w[RELEVANCE DISTANCE]).description("How results are ranked: RELEVANCE (default) or DISTANCE for categorical queries")
      optional(:strict_type_filtering).filled(:bool).description("When true, only places matching includedType are returned")
      optional(:fields).filled(:string).description("Comma-separated X-Goog-FieldMask of place fields to return, each prefixed with 'places.' (controls billing)")
    end

    def call(text_query:, page_size: nil, page_token: nil, included_type: nil, language_code: nil,
             region_code: nil, open_now: nil, min_rating: nil, rank_preference: nil,
             strict_type_filtering: nil, fields: nil)
      body = { textQuery: text_query }
      body[:pageSize] = page_size if page_size
      body[:pageToken] = page_token if page_token
      body[:includedType] = included_type if included_type
      body[:languageCode] = language_code if language_code
      body[:regionCode] = region_code if region_code
      body[:openNow] = open_now unless open_now.nil?
      body[:minRating] = min_rating if min_rating
      body[:rankPreference] = rank_preference if rank_preference
      body[:strictTypeFiltering] = strict_type_filtering unless strict_type_filtering.nil?

      places_post("places:searchText", fields: fields.presence || DEFAULT_FIELDS, body: body)
    end
  end
end
