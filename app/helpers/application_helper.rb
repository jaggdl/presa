module ApplicationHelper
  # Render a service's brand icon, as declared on the model, padded and framed
  # with a subtle border so it reads as a tile. `size` sets the Tailwind
  # height/width classes, defaulting to a small avatar (h-7 w-7).
  def service_icon(service, size: "h-7 w-7")
    image = image_tag service.icon, class: (service.invert_icon? ? "#{size} invert" : size), "aria-hidden": true
    content_tag :span, image,
                class: "inline-flex items-center justify-center p-2.5 bg-zinc-900 rounded-lg border border-zinc-700"
  end
end
