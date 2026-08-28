# frozen_string_literal: true

module GoogleAnalytics
  # Returns annotations (notes left on a GA4 property for specific dates or
  # periods, e.g. release or campaign notes) via the Admin API alpha endpoint.
  class ListPropertyAnnotationsTool < Base
    description "List the annotations for a Google Analytics 4 property (notes left on specific dates or periods)"

    arguments do
      required(:property_id).filled(:string).description("The Google Analytics property ID. Accepted formats are a number (e.g. 1234567) or a string consisting of 'properties/' followed by a number")
    end

    def call(property_id:)
      ga_get(ADMIN_API, "/v1alpha/#{property_resource_name(property_id)}/reportingDataAnnotations")
    end
  end
end
