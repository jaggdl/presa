# frozen_string_literal: true

module GoogleAnalytics
  # Returns the Google Ads links configured on a GA4 property.
  class ListGoogleAdsLinksTool < Base
    description "List the Google Ads links for a Google Analytics 4 property"

    arguments do
      required(:property_id).filled(:string).description("The Google Analytics property ID. Accepted formats are a number (e.g. 1234567) or a string consisting of 'properties/' followed by a number")
    end

    def call(property_id:)
      ga_get(ADMIN_API, "/v1beta/#{property_resource_name(property_id)}/googleAdsLinks")
    end
  end
end
