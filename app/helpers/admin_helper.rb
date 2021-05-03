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
end
