# frozen_string_literal: true

module GoogleAnalytics
  # Runs a Google Analytics 4 report against the Data API (v1beta).
  class RunReportTool < Base
    description <<~DESC.strip
      Run a Google Analytics Data API report. Standard dimensions/metrics follow the GA4 API
      schema (https://developers.google.com/analytics/devguides/reporting/data/v1/api-schema);
      custom dimensions/metrics come from get_custom_dimensions_and_metrics.
      date_ranges entries use { "start_date", "end_date" } (e.g. "30daysAgo"/"today", or explicit
      YYYY-MM-DD, optionally "name"). Free-form filter/order arguments accept the GA4 REST object
      shape, e.g. a dimension filter: { "filter": { "field_name": "eventName",
      "string_filter": { "match_type": "BEGINS_WITH", "value": "add" } } }.
    DESC

    arguments do
      required(:property_id).filled(:string).description("The Google Analytics property ID. Accepted formats are a number (e.g. 1234567) or a string consisting of 'properties/' followed by a number")
      required(:date_ranges).array(:hash) do
        required(:start_date).filled(:string).description("Start date: YYYY-MM-DD or relative like '30daysAgo'")
        required(:end_date).filled(:string).description("End date: YYYY-MM-DD or relative like 'yesterday'/'today'")
        optional(:name).filled(:string).description("Optional name for the date range")
      end.description("List of date ranges to include in the report")
      required(:dimensions).array(:string).description("Dimensions to include in the report, e.g. 'date', 'sessionDefaultChannelGroup'")
      required(:metrics).array(:string).description("Metrics to include in the report, e.g. 'activeUsers', 'sessions'")
      optional(:dimension_filter).hash.description("A Data API FilterExpression applied to dimensions. The field_name must be a dimension. See GA4 REST docs for the shape.")
      optional(:metric_filter).hash.description("A Data API FilterExpression applied to metrics. The field_name must be a metric. See GA4 REST docs for the shape.")
      optional(:order_bys).array(:hash).description("List of Data API OrderBy objects, e.g. { 'metric': { 'metric_name': 'eventCount' }, 'desc': true }. Dimensions/metrics used must also be in the report.")
      optional(:limit).filled(:integer, gt?: 0).description("Maximum rows to return (positive integer <= 250,000)")
      optional(:offset).filled(:integer).description("Row count of the first returned row (paginating)")
      optional(:currency_code).filled(:string).description("ISO4217 currency code, e.g. 'USD'; defaults to the property's currency")
      optional(:return_property_quota).filled(:bool).description("Whether to return property quota in the response (default false)")
    end

    def call(property_id:, date_ranges:, dimensions:, metrics:, dimension_filter: nil, metric_filter: nil,
             order_bys: nil, limit: nil, offset: nil, currency_code: nil, return_property_quota: false)
      body = {
        dateRanges: camelize_keys_deep(date_ranges),
        dimensions: dimensions.map { |d| { name: d } },
        metrics: metrics.map { |m| { name: m } }
      }
      body[:dimensionFilter] = camelize_keys_deep(dimension_filter) if dimension_filter
      body[:metricFilter] = camelize_keys_deep(metric_filter) if metric_filter
      body[:orderBys] = camelize_keys_deep(order_bys) if order_bys
      body[:limit] = limit if limit
      body[:offset] = offset if offset
      body[:currencyCode] = currency_code if currency_code
      body[:returnPropertyQuota] = return_property_quota if return_property_quota

      ga_post(DATA_API, "/v1beta/#{property_resource_name(property_id)}:runReport", body: body)
    end
  end
end
