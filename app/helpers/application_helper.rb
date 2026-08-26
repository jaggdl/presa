module ApplicationHelper
  # Render a service's brand icon, as declared on the model.
  def service_icon(service)
    cls = "inline h-7 w-7 rounded"
    cls += " invert" if service.invert_icon?
    image_tag service.icon, class: cls, "aria-hidden": true
  end
end
