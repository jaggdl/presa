class ToolInvocation < ApplicationRecord
  RESULT_CAP = 8_192

  belongs_to :api_token
  has_one :workspace, through: :api_token

  belongs_to :service, optional: true

  scope :recent, ->(limit = 50) { order(created_at: :desc).limit(limit) }
  scope :for_workspace, ->(workspace) { joins(:api_token).where(api_tokens: { workspace_id: workspace.id }) }

  def self.record!(api_token: nil, service: nil, tool_name:, arguments:, **attrs)
    return if api_token.nil?

    create!(
      api_token: api_token,
      service: service,
      tool_name: tool_name,
      arguments: truncate(arguments),
      status: attrs[:status] || "success",
      error_message: attrs[:error_message],
      duration_ms: attrs[:duration_ms],
      response: truncate(attrs[:response])
    )
  rescue StandardError => e
    Rails.logger.error("Failed to record tool invocation: #{e.message}")
  end

  def success?
    status == "success"
  end

  def self.truncate(value)
    return value if value.nil?

    encoded = value.is_a?(String) ? value : JSON.generate(value)
    return value if encoded.bytesize <= RESULT_CAP

    { truncated: true, original_bytes: encoded.bytesize }
  end
end