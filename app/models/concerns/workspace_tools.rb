# frozen_string_literal: true

# Provides the plain-text, token-facing view of a workspace's allowed tools for
# the `/bots` API. Keeps Bots::ToolsController thin by owning both the exposure
# query and the plain-text formatting.
module WorkspaceTools
  extend ActiveSupport::Concern

  # The bound tool classes this workspace may use, honoring each service's
  # allowed_tools — the same exposure path the MCP server uses.
  def allowed_tools
    workspace_services.includes(:service).flat_map do |wc|
      ApplicationTool.expose_for(wc.service).select { |tool| wc.tool_allowed?(tool.tool_key) }
    end
  end

  # Compact listing: tool name plus a truncated one-line description.
  def tools_list_text
    lines = allowed_tools.map { |tool| "#{tool.tool_name}: #{truncate(flatten(tool.description))}" }
    lines.any? ? "#{lines.join("\n")}\n" : "No tools available.\n"
  end

# High-level context about the workspace for a bot: name and linked services
# (each with its kind and tool count). See GET /bots/workspace.
def workspace_context_text
  lines = []
  lines << "Workspace: #{name}"
  lines << "Description: #{flatten(description)}" if description.presence

  joins = workspace_services.includes(:service)
  tools_by_service = allowed_tools.group_by(&:service_id)

  lines << ""
  lines << "Services:"
  joins.each do |join|
    count = tools_by_service.fetch(join.service_id, []).count
    lines << "  - #{join.service.name} (#{join.service.kind}): #{count} #{'tool'.pluralize(count)}"
  end
  lines << "  (none)" if joins.empty?

  "#{lines.join("\n")}\n"
end

  # Full detail for one tool: name, description, and argument schema.
  def tool_detail_text(tool)
    lines = [ tool.tool_name ]
    lines << "Description: #{flatten(tool.description)}" if tool.description.presence

    params = tool.input_parameters
    if params.any?
      lines << "Arguments:"
      params.each do |param|
        type = param[:type]
        required = param[:required] ? "required" : "optional"
        line = "  - #{param[:name]} (#{type} | #{required})"
        line << " — #{flatten(param[:description])}" if param[:description].presence
        lines << line
      end
    else
      lines << "Arguments: (none)"
    end

    "#{lines.join("\n")}\n"
  end

  # Locate a single allowed tool by its exposed MCP name, or nil.
  def find_allowed_tool(name)
    allowed_tools.find { |tool| tool.tool_name == name }
  end

  # Execute a given allowed tool with keyword args. Runs through the same
  # validation, authorization, and invocation-logging path as the MCP server.
  # Returns the tool's result (the framework returns [result, meta]; we keep
  # the result).
  def execute_tool(tool, arguments)
    result, = tool.new.call_with_schema_validation!(**arguments)
    result
  end

  # Parse a raw JSON request body into keyword args. Blank body means no args.
  def parse_tool_arguments(raw_body)
    return {} if raw_body.blank?

    parsed = JSON.parse(raw_body)
    parsed.respond_to?(:transform_keys) ? parsed.transform_keys(&:to_sym) : parsed
  rescue JSON::ParserError
    raise InvalidToolBody
  end

  # Run a named allowed tool with a raw JSON body and render the result as
  # plain text. Returns the text for the controller to emit. Raises
  # UnknownTool / NotAllowedToolError / InvalidToolBody / tool errors, which
  # the controller maps to status codes.
  def execute_tool_text(tool_name, raw_body)
    tool = find_allowed_tool(tool_name)
    raise UnknownTool, tool_name unless tool

    args = parse_tool_arguments(raw_body)
    tool_result_text(execute_tool(tool, args))
  end

  # Raised when the requested tool is not amongst the workspace's allowed tools.
  class UnknownTool < StandardError; end

  # A typed error for malformed JSON bodies, so the controller can respond 400.
  class InvalidToolBody < StandardError; end

  # Render a tool result as plain text. The MCP content envelope is unwrapped to
  # its inner text; whatever the tool returned is passed through as-is.
  def tool_result_text(result)
    text = unwrap_content(result)
    text = "OK" if text.nil?
    "#{text}\n"
  end

  private

  # Fast-mcp wraps string results in an MCP content envelope
  # `{ "content" => [ { "type" => "text", "text" => "..." } ] }`. Unwrap it to
  # the inner text so bot clients get the actual result.
  def unwrap_content(result)
    content = result.is_a?(Hash) && result["content"].is_a?(Array) ? result["content"] : nil
    return result unless content

    texts = content.filter_map { |block| block["text"] if block["type"] == "text" }
    texts.empty? ? result : texts.join("\n")
  end

  # Collapse newlines/whitespace in prose so one output line maps to one field.
  def flatten(text)
    text.to_s.strip.gsub(/\s+/, " ")
  end

  # A one-line, truncated summary of a description.
  def truncate(text, length: 140)
    return text if text.length <= length

    "#{text[0, length - 1].rstrip}…"
  end
end
