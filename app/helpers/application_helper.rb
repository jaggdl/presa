require "commonmarker"

module ApplicationHelper
  # The public base URL of the instance, e.g. "https://presa.example.com".
  # Resolves from the BASE_URL env var, else the origin of the current request
  # (the host/port the caller is actually using), else a placeholder.
  def base_url
    ENV["BASE_URL"].presence || request.base_url.presence || "<your-presa-url>"
  end

  # The stable identifier used to select an allowed tool: the remote tool name
  # for proxied MCP tools, otherwise the tool's kind (e.g. "search_user_media").
  def tool_key(bound_tool)
    bound_tool.tool_key
  end

  # Renders a Markdown string to HTML via Commonmarker (matching the markdown
  # handling used across the app) inside a Tailwind Typography `prose` container.
  # The syntax_highlighter plugin emits server-side highlighted code blocks.
  def render_markdown(source)
    return "" if source.blank?

    html = Commonmarker.to_html(source.to_s, plugins: { syntax_highlighter: { theme: "base16-ocean.dark" } })
    content_tag(:div, raw(html), class: "prose prose-invert prose-zinc max-w-none")
  end

  private

  # Classifies how loaded a workspace is by the number of allowed tools, so a
  # single "read the thermometer" glance conveys whether a workspace has few,
  # a reasonable number, or far too many tools. Returns the icon name, Tailwind
  # text color, and a human label for the level.
  def tool_weight_level(count)
    if count >= 80
      { icon: "flame",   label: "High",     text: "text-red-400" }
    elsif count >= 30
      { icon: "activity", label: "Moderate", text: "text-amber-400" }
    else
      { icon: "leaf",    label: "Low",      text: "text-emerald-400" }
    end
  end

  # Formats a tool invocation's arguments JSON hash as a compact, readable
  # "key: value" string, so rows show "movieId: 5, query: dune" instead of raw
  # JSON syntax. Strings are quoted to make empty strings and spaces visible.
  def format_invocation_arguments(arguments)
    return "–" if arguments.blank?
    return "truncated" if arguments.is_a?(Hash) && arguments["truncated"]

    if arguments.is_a?(Hash)
      arguments.map { |key, value| "#{key}: #{format_argument_value(value)}" }.join(", ")
    else
      format_argument_value(arguments)
    end
  end

  def format_argument_value(value)
    case value
    when String then value.inspect
    when Hash   then value.map { |k, v| "#{k}=#{format_argument_value(v)}" }.join(", ")
    when Array  then value.map { |v| format_argument_value(v) }.join(", ")
    else value.to_s
    end
  end

  # Formats a tool invocation's arguments as one line per key, with the key and
  # its value separated so the expanded log reads as a tidy checklist. Always
  # returns an array of {key:, value:} rows.
  def format_invocation_args_multiline(arguments)
    return if arguments.blank?
    return [ { key: nil, value: "truncated" } ] if arguments.is_a?(Hash) && arguments["truncated"]

    if arguments.is_a?(Hash)
      arguments.map { |key, value| { key: key, value: format_argument_value(value) } }
    else
      [ { key: nil, value: format_argument_value(arguments) } ]
    end
  end

  # Pretty-prints a tool invocation's output as indented JSON, falling back to
  # the plain value for non-hash/array payloads.
  def format_invocation_output(response)
    return if response.blank?
    return "truncated" if response.is_a?(Hash) && response["truncated"]

    if response.is_a?(Hash) || response.is_a?(Array)
      JSON.pretty_generate(response)
    else
      response.to_s
    end
  end

  # Render an OAuth provider's brand icon in the same framed tile style as a
  # service icon, so the credentials index reads like the services index. The
  # image is looked up on OauthClientCredential by provider (e.g.
  # "spotify.png"), falling back to the generic placeholder.
  def oauth_provider_icon(provider, size: "h-7 w-7")
    image = image_tag OauthClientCredential.icon_for(provider), class: "#{size} shrink-0", "aria-hidden": true
    content_tag :span, image,
                class: "inline-flex items-center justify-center shrink-0 p-2.5 bg-zinc-900 rounded-lg border border-zinc-700"
  end

  # <option> HTML for the OAuth scopes multi-select on the credential form.
  # Only OpenAPI-kind providers (Oauth::Base::Dynamic) declare a scope list
  # ({key => description} extracted from the spec's OAuth flow); static
  # providers (Google, Spotify, ...) have no canonical list, so their
  # credential form keeps the plain text field.
  def oauth_scope_select_options(credential)
    provider = Oauth::Base.for_provider(credential.provider.to_s)
    return "".html_safe unless provider.is_a?(Oauth::Base::Dynamic)

    scopes = provider.scopes
    return "".html_safe unless scopes.is_a?(Hash) && scopes.any?

    selected = Array(credential.scope.to_s.split).map(&:strip)
    scopes.map do |key, desc|
      attrs = +%( value="#{ERB::Util.html_escape(key)}")
      attrs << %( selected) if selected.include?(key.to_s)
      attrs << %( title="#{ERB::Util.html_escape(desc.to_s)}") if desc.present?
      %(<option#{attrs}>#{ERB::Util.html_escape(key)}</option>)
    end.join.html_safe
  end

  # Render a service's brand icon, as declared on the model, padded and framed
  # with a subtle border so it reads as a tile. `size` picks one of four fixed
  # presets; `:md` is the default.
  SERVICE_ICON_SIZES = {
    sm:  { dims: "h-3 w-3",       padding: "p-0.5" }, # dense rows, e.g. tool invocations
    md:  { dims: "h-5 w-5",     padding: "p-1.5" },   # sidebar/row tiles
    lg:  { dims: "h-8 w-8",     padding: "p-2" },    # cards, forms
    xl:  { dims: "h-14 w-14",   padding: "p-2" }     # page headers
  }.freeze

  def service_icon(service, size: :md)
    size = SERVICE_ICON_SIZES.fetch(size, SERVICE_ICON_SIZES[:md])
    dims = service.invert_icon? ? "#{size[:dims]} invert" : size[:dims]
    image = image_tag service.icon, class: "#{dims} shrink-0", "aria-hidden": true
    content_tag :span, image,
                class: "inline-flex items-center justify-center shrink-0 #{size[:padding]} bg-zinc-900 rounded-md border border-zinc-700"
  end

  # A small deck of overlapping service icons, cascading right-and-down like
  # a spread of cards (up to `max`). Each tile is offset from the previous one.
  # If there are more services than `max`, a "+N" badge is appended.
  def service_icon_stack(services, max: 3)
    icons = services.first(max)
    return if icons.blank?

    tile = 48 # p-2 + h-8/w-8 img => 48px square
    offset = 20
    extra = services.count - icons.length
    width = offset * (icons.length - 1) + tile
    height = tile

    content_tag :div, class: "service-icon-stack flex-shrink-0",
                style: "width: #{width + 10}px; height: #{height}px; position: relative;" do
      stack = icons.each_with_index.map do |service, i|
        content_tag :div, service_icon(service, size: :lg),
                    style: "position: absolute; top: 0; left: #{i * offset}px;"
      end
      if extra.positive?
        stack << content_tag(:div, "+#{extra}",
                             class: "pill h-5 justify-center px-1.5",
                             style: "position: absolute; bottom: -4px; left: #{offset * (icons.length - 1) + tile - 20}px;")
      end
      safe_join(stack)
    end
  end

  # The OpenAPI integration wizard uses these (step2 renders them).

  # Serialized operations (operation_id/label/response_fields) for the step-2
  # health-check pickers (Stimulus repopulates the identity field per operation).
  def operations_json(definition)
    ops = definition["operations"] || []
    ops.map do |op|
      {
        "operation_id" => op["operation_id"],
        "label" => "#{op["method"]} #{op["path"]}",
        "response_fields" => op["response_fields"] || []
      }
    end.to_json.html_safe
  end

  # A human string for how a scheme's credential is transmitted, e.g. "x-api-key: …".
  def auth_send_hint(slot)
    case slot["kind"].to_s
    when "apikey"
      name = slot["param_name"].to_s.presence || slot["name"].to_s
      case slot["in"].to_s
      when "query" then "#{name}= …"
      when "cookie" then "Cookie: #{name}=…"
      else "#{name}: …"
      end
    when "basic", "bearer"
      slot["in_desc"].to_s.presence || "Authorization: …"
    else
      slot["in_desc"].to_s.presence || "…"
    end
  end

  # Options for the health-check operation picker: method + path + summary.
  def health_op_options(definition)
    (definition["operations"] || []).map do |op|
      label = "#{op["method"]} #{op["path"]}"
      label += " — #{op["summary"]}" if op["summary"].present?
      [ label, op["operation_id"] ]
    end
  end
end
