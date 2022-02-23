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
    deduced_scope(request).to_s == (group[:children][0][:parent] || group_name).to_s
  end

  def children?(group)
    group[:children].length > 1
  end

  def nav_path(group, group_name)
    if children?(group)
      "#{admin_path}/#{group_name}/#{group[:children].detect { |child| child[:visible] }[:controller]}"
    else
      "#{admin_path}/#{group[:children][0][:controller]}"
    end
  end
end
