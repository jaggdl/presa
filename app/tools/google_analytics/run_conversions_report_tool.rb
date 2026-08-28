# frozen_string_literal: true

module GoogleAnalytics
  # Runs a conversions report against the Data API alpha endpoint, covering
  # conversions, ad performance, return on ad spend (ROAS) and attribution.
  # Use this instead of run_report when specifically reporting on conversions.
  class RunConversionsReportTool < Base
    description <<~DESC.strip
      Run a Google Analytics conversions report (Data API alpha). Use instead of run_report when you
      need to report on conversions, ad clicks/cost, return on ad spend (ROAS), or attribution.
      Check https://developers.google.com/analytics/devguides/reporting/data/v1/conversions-api-basics.
      The allowed dimensions/metrics are the conversions-specific standard set. conversion_spec
      should contain "conversion_actions" (list of resource names, or [] for all actions) and an
      "attribution_model" (e.g. "DATA_DRIVEN" or "LAST_CLICK").
    DESC

    arguments do
      required(:property_id).filled(:string).description("The Google Analytics property ID. Accepted formats are a number (e.g. 1234567) or a string consisting of 'properties/' followed by a number")
      required(:date_ranges).array(:hash) do
        required(:start_date).filled(:string).description("Start date: YYYY-MM-DD or relative like '30daysAgo'")
        required(:end_date).filled(:string).description("End date: YYYY-MM-DD or relative like 'yesterday'/'today'")
        optional(:name).filled(:string).description("Optional name for the date range")
      end.description("List of date ranges to include in the report")
      required(:dimensions).array(:string).description("Dimensions to include; allowed set includes campaignName, country, deviceCategory, defaultChannelGroup, source, sourceMedium, etc.")
      required(:metrics).array(:string).description("Metrics to include; allowed set includes advertiserAdClicks, advertiserAdCost, allConversionsByInteractionDate, returnOnAdSpendByConversionDate, etc.")
      required(:conversion_spec).hash.description("Conversion specification: { 'conversion_actions': [...], 'attribution_model': 'DATA_DRIVEN' }")
      optional(:dimension_filter).hash.description("A Data API FilterExpression applied to dimensions. See GA4 REST docs for the shape.")
      optional(:metric_filter).hash.description("A Data API FilterExpression applied to metrics. See GA4 REST docs for the shape.")
      optional(:order_bys).array(:hash).description("List of Data API OrderBy objects")
      optional(:limit).filled(:integer, gt?: 0).description("Maximum rows to return (positive integer <= 250,000)")
      optional(:offset).filled(:integer).description("Row count of the first returned row (paginating)")
      optional(:currency_code).filled(:string).description("ISO4217 currency code, e.g. 'USD'; defaults to the property's currency")
      optional(:return_property_quota).filled(:bool).description("Whether to return property quota in the response (default false)")
    end

    def call(property_id:, date_ranges:, dimensions:, metrics:, conversion_spec:,
             dimension_filter: nil, metric_filter: nil, order_bys: nil, limit: nil, offset: nil,
             currency_code: nil, return_property_quota: false)
      body = {
        dateRanges: camelize_keys_deep(date_ranges),
        dimensions: dimensions.map { |d| { name: d } },
        metrics: metrics.map { |m| { name: m } },
        conversionSpec: camelize_keys_deep(conversion_spec)
      }
      body[:dimensionFilter] = camelize_keys_deep(dimension_filter) if dimension_filter
      body[:metricFilter] = camelize_keys_deep(metric_filter) if metric_filter
      body[:orderBys] = camelize_keys_deep(order_bys) if order_bys
      body[:limit] = limit if limit
      body[:offset] = offset if offset
      body[:currencyCode] = currency_code if currency_code
      body[:returnPropertyQuota] = return_property_quota if return_property_quota

      ga_post(DATA_API, "/v1alpha/#{property_resource_name(property_id)}:runReport", body: body)
    end
  end
end
