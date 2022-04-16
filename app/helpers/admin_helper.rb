module AdminHelper
  def deduced_controller(request)
    request.path.split("/").fourth
  end

  def deduced_scope(request)
    request.path.split("/").third
  end

  def display_name(group_name)
    group_name.to_s.tr("_", " ").titleize
  end

  def dom_safe_name(group_name)
    group_name.gsub(/\s+|\./, "_").gsub(/\A(\d)/, '_\1')
  end

  def current?(request, group, group_name)
    deduced_scope(request).to_s == (group.children.first&.parent || group_name).to_s
  end

  def nav_path(group, group_name)
    if group.has_multiple_children?
      # NOTE: [@jeremyf] I'm unclear what to do if we have no match; this logic
      # carries forward the prior implementation.
      visible_child_controller = group.children.detect(&:visible?)&.controller
      "#{admin_path}/#{group_name}/#{visible_child_controller}"
    else
      # NOTE: We assume that if there's only one child that it is visible
      "#{admin_path}/#{group.children.first&.controller}"
    end
  end
end
