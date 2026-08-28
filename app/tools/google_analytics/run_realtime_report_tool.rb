# frozen_string_literal: true

module GoogleAnalytics
  # Runs a realtime report against the Data API (v1beta), for data from the
  # last ~30 minutes. Realtime reports use realtime dimensions/metrics and
  # can't use custom metrics or date ranges.
  class RunRealtimeReportTool < Base
    description <<~DESC.strip
      Run a Google Analytics realtime report (data from the last ~30 minutes). Use the realtime
      dimension/metric schema (https://developers.google.com/analytics/devguides/reporting/data/v1/realtime-api-schema).
      Realtime reports can't use custom metrics or date ranges.
    DESC

    arguments do
      required(:property_id).filled(:string).description("The Google Analytics property ID. Accepted formats are a number (e.g. 1234567) or a string consisting of 'properties/' followed by a number")
      required(:dimensions).array(:string).description("Realtime dimensions to include, e.g. 'unifiedScreenName', 'deviceCategory'")
      required(:metrics).array(:string).description("Realtime metrics to include, e.g. 'activeUsers', 'screenPageViews'")
      optional(:dimension_filter).hash.description("A Data API FilterExpression applied to dimensions. See GA4 REST docs for the shape.")
      optional(:metric_filter).hash.description("A Data API FilterExpression applied to metrics. See GA4 REST docs for the shape.")
      optional(:order_bys).array(:hash).description("List of Data API OrderBy objects, e.g. { 'dimension': { 'dimension_name': 'unifiedScreenName' } }")
      optional(:limit).filled(:integer, gt?: 0).description("Maximum rows to return (positive integer <= 250,000)")
      optional(:offset).filled(:integer).description("Row count of the first returned row (paginating)")
      optional(:return_property_quota).filled(:bool).description("Whether to return realtime property quota in the response (default false)")
    end

    def call(property_id:, dimensions:, metrics:, dimension_filter: nil, metric_filter: nil,
             order_bys: nil, limit: nil, offset: nil, return_property_quota: false)
      body = {
        dimensions: dimensions.map { |d| { name: d } },
        metrics: metrics.map { |m| { name: m } }
      }
      body[:dimensionFilter] = camelize_keys_deep(dimension_filter) if dimension_filter
      body[:metricFilter] = camelize_keys_deep(metric_filter) if metric_filter
      body[:orderBys] = camelize_keys_deep(order_bys) if order_bys
      body[:limit] = limit if limit
      body[:offset] = offset if offset
      body[:returnPropertyQuota] = return_property_quota if return_property_quota

      ga_post(DATA_API, "/v1beta/#{property_resource_name(property_id)}:runRealtimeReport", body: body)
    end
  end
end
