module Admin
  class ReadOnlyDatabaseController < Admin::ApplicationController
    def show
      @health_check = ReadOnlyDatabaseService.health_check
      @connection_info = ReadOnlyDatabaseService.connection_info
      @available = ReadOnlyDatabaseService.available?
    end

    def test_connection
      begin
        ReadOnlyDatabaseService.with_connection do |conn|
          result = conn.execute("SELECT COUNT(*) as user_count FROM users")
          @user_count = result.first["user_count"]
          @success = true
        end
      rescue StandardError => e
        @error = e.message
        @success = false
      end

      respond_to do |format|
        format.html { redirect_to admin_read_only_database_path }
        format.json { render json: { success: @success, user_count: @user_count, error: @error } }
      end
    end

    def reset_pool
      ReadOnlyDatabaseService.reset_connection_pool!
      flash[:success] = "Read-only database connection pool reset successfully"
      redirect_to admin_read_only_database_path
    end
  end
end
