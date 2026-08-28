# frozen_string_literal: true

module GoogleAnalytics
  # Returns details about a GA4 property.
  class GetPropertyDetailsTool < Base
    description "Return details about a Google Analytics 4 property"

    arguments do
      required(:property_id).filled(:string).description("The Google Analytics property ID. Accepted formats are a number (e.g. 1234567) or a string consisting of 'properties/' followed by a number")
    end

    def call(property_id:)
      ga_get(ADMIN_API, "/v1beta/#{property_resource_name(property_id)}")
    end
  end
end
