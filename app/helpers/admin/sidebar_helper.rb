module Admin
  module SidebarHelper
    def sidebar_item_active?(item)
      corresponding_controller_name == item.controller.to_s
    end

    private

    def corresponding_controller_name
      return corresponding_menu_item.controller.to_s if corresponding_menu_item.present?

      deduced_controller(request)
    end

    def corresponding_menu_item
      return if deduced_scope(request).blank?
      return if deduced_controller(request).blank?

      AdminMenu.nested_menu_items(deduced_scope(request), deduced_controller(request))
    end
  end
end
