# frozen_string_literal: true

module GoogleAnalytics
  # Runs a funnel report against the Data API alpha endpoint. Funnel reports
  # analyze user progression through a defined set of steps.
  class RunFunnelReportTool < Base
    description <<~DESC.strip
      Run a Google Analytics funnel report (Data API alpha). Check
      https://developers.google.com/analytics/devguides/reporting/data/v1/funnels for details.
      Each funnel step is a hash with a "name" plus either a "filter_expression" (full funnel
      FilterExpression) or an "event" name, e.g. { "name": "Page view", "event": "page_view" }.
    DESC

    arguments do
      required(:property_id).filled(:string).description("The Google Analytics property ID. Accepted formats are a number (e.g. 1234567) or a string consisting of 'properties/' followed by a number")
      required(:funnel_steps).array(:hash).description("List of funnel steps; each has a 'name' plus either a 'filter_expression' or an 'event'")
      optional(:date_ranges).array(:hash) do
        required(:start_date).filled(:string).description("Start date: YYYY-MM-DD or relative like '30daysAgo'")
        required(:end_date).filled(:string).description("End date: YYYY-MM-DD or relative like 'yesterday'/'today'")
        optional(:name).filled(:string).description("Optional name for the date range")
      end.description("List of date ranges to include in the report")
      optional(:funnel_breakdown).hash.description("Optional breakdown to segment the funnel by a dimension, e.g. { 'breakdown_dimension': 'deviceCategory' }")
      optional(:funnel_next_action).hash.description("Optional next-action analysis, e.g. { 'next_action_dimension': 'eventName', 'limit': 5 }")
      optional(:segments).array(:hash).description("Optional list of segments to apply to the funnel (Data API Segment objects)")
      optional(:return_property_quota).filled(:bool).description("Whether to return property quota in the response (default false)")
    end

    def call(property_id:, funnel_steps:, date_ranges: nil, funnel_breakdown: nil, funnel_next_action: nil,
             segments: nil, return_property_quota: false)
      raise ArgumentError, "funnel_steps must contain at least one step" if funnel_steps.blank?

      body = { funnel: { steps: camelize_keys_deep(funnel_steps) } }
      body[:dateRanges] = camelize_keys_deep(date_ranges) if date_ranges
      body[:funnelBreakdown] = camelize_keys_deep(funnel_breakdown) if funnel_breakdown
      body[:funnelNextAction] = camelize_keys_deep(funnel_next_action) if funnel_next_action
      body[:segments] = camelize_keys_deep(segments) if segments
      body[:returnPropertyQuota] = return_property_quota if return_property_quota

      ga_post(DATA_API, "/v1alpha/#{property_resource_name(property_id)}:runFunnelReport", body: body)
    end
  end
end
