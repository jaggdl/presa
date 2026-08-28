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

  # Render an OAuth provider's brand icon in the same framed tile style as a
  # service icon, so the credentials index reads like the services index. The
  # image is looked up on OauthClientCredential by provider (e.g.
  # "spotify.png"), falling back to the generic placeholder.
  def oauth_provider_icon(provider, size: "h-7 w-7")
    image = image_tag OauthClientCredential.icon_for(provider), class: "#{size} shrink-0", "aria-hidden": true
    content_tag :span, image,
                class: "inline-flex items-center justify-center shrink-0 p-2.5 bg-zinc-900 rounded-lg border border-zinc-700"
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
                             class: "inline-flex items-center justify-center h-5 rounded-full px-1.5 bg-zinc-700 border border-zinc-600 text-zinc-100 text-[10px]",
                             style: "position: absolute; bottom: -4px; left: #{offset * (icons.length - 1) + tile - 20}px;")
      end
      safe_join(stack)
    end
  end
end
