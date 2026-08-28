# frozen_string_literal: true

module GoogleAnalytics
  # Retrieves a property's custom dimensions and metrics from the Data API
  # metadata, split into two lists. Used to learn what custom fields a report
  # may reference.
  class GetCustomDimensionsAndMetricsTool < Base
    description "Return the custom dimensions and metrics defined for a Google Analytics 4 property"

    arguments do
      required(:property_id).filled(:string).description("The Google Analytics property ID. Accepted formats are a number (e.g. 1234567) or a string consisting of 'properties/' followed by a number")
    end

    def call(property_id:)
      metadata = ga_get(DATA_API, "/v1beta/#{property_resource_name(property_id)}/metadata")

      {
        "custom_dimensions" => Array(metadata["dimensions"]).select { |d| d["customDefinition"] },
        "custom_metrics" => Array(metadata["metrics"]).select { |m| m["customDefinition"] }
      }
    end
  end
end
