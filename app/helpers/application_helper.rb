module ApplicationHelper
  # The public base URL of the instance, e.g. "https://presa.example.com".
  # Resolves from the BASE_URL env var, else the origin of the referring page
  # (which typically matches the public host), else a placeholder.
  def base_url
    ENV["BASE_URL"].presence || referer_origin.presence || "<your-presa-url>"
  end

  private

  def referer_origin
    referer = request.referer
    return if referer.blank?

    uri = URI.parse(referer)
    origin = "#{uri.scheme}://#{uri.host}"
    origin = "#{origin}:#{uri.port}" if uri.host.match?(/\A\d{1,3}(\.\d{1,3}){3}\z/)
    origin.presence
  rescue URI::InvalidURIError, ArgumentError
    nil
  end

  # Render a service's brand icon, as declared on the model, padded and framed
  # with a subtle border so it reads as a tile. `size` sets the Tailwind
  # height/width classes, defaulting to a small avatar (h-7 w-7).
  def service_icon(service, size: "h-7 w-7")
    image = image_tag service.icon, class: (service.invert_icon? ? "#{size} invert" : size), "aria-hidden": true
    content_tag :span, image,
                class: "inline-flex items-center justify-center p-2.5 bg-zinc-900 rounded-lg border border-zinc-700"
  end

  # A small deck of overlapping service icons, cascading right-and-down like
  # a spread of cards (up to `max`). Each tile is offset from the previous one.
  # If there are more services than `max`, a "+N" badge is appended.
  def service_icon_stack(services, max: 3)
    icons = services.first(max)
    return if icons.blank?

    tile = 52 # each tile is p-2.5 + h-8/w-8 img => 52px square
    offset = 20
    extra = services.count - icons.length
    width = offset * (icons.length - 1) + tile
    height = tile

    content_tag :div, class: "service-icon-stack flex-shrink-0",
                style: "width: #{width + 10}px; height: #{height}px; position: relative;" do
      stack = icons.each_with_index.map do |service, i|
        content_tag :div, service_icon(service, size: "h-8 w-8"),
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
