module Admin
  module Users
    class ExportBulkDataController < Admin::ApplicationController
      layout "admin"

      def index
      end

      def create
        AuditLog.create(
          user: current_user,
          category: "admin.export_bulk_data.users",
          roles: current_user.roles_name,
          slug: "export_bulk_data",
          data: {
            user_id: current_user.id
          },
        )
        Users::ExportBulkDataWorker.perform_async
        flash[:success] = "Export job sent! You should receive the data as a CSV soon."
        redirect_to admin_users_export_bulk_data_index_path
      end
    end
  end
end
