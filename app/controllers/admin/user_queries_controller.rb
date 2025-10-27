module Admin
  class UserQueriesController < Admin::ApplicationController
    before_action :set_user_query, only: %i[show edit update destroy test_execute toggle_active]

    def index
      @user_queries = UserQuery.includes(:created_by)
        .order(created_at: :desc)
        .page(params[:page])
        .per(20)

      # Filter by active status if specified
      @user_queries = @user_queries.where(active: params[:active]) if params[:active].present?

      # Search by name or description
      return unless params[:search].present?

      search_term = "%#{params[:search]}%"
      @user_queries = @user_queries.where(
        "name ILIKE ? OR description ILIKE ?",
        search_term,
        search_term,
      )
    end

    def show
      @estimated_count = @user_query.estimated_user_count
    end

    def new
      @user_query = UserQuery.new
    end

    def edit
    end

    def create
      @user_query = UserQuery.new(user_query_params)
      @user_query.created_by = current_user

      if @user_query.save
        redirect_to admin_user_query_path(@user_query),
                    notice: "User query was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if @user_query.update(user_query_params)
        redirect_to admin_user_query_path(@user_query),
                    notice: "User query was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @user_query.destroy
      redirect_to admin_user_queries_path,
                  notice: "User query was successfully deleted."
    end

    def test_execute
      limit = params[:limit]&.to_i || 10

      begin
        executor = UserQueryExecutor.new(@user_query, limit: limit)
        @test_users = executor.test_execute
        @execution_errors = executor.error_messages

        if @execution_errors.any?
          flash.now[:alert] = "Query execution failed: #{@execution_errors.join(', ')}"
        else
          flash.now[:notice] = "Query executed successfully. Found #{@test_users.count} users."
        end
      rescue StandardError => e
        @execution_errors = [e.message]
        flash.now[:alert] = "Query execution failed: #{e.message}"
      end

      render :show
    end

    def toggle_active
      @user_query.update!(active: !@user_query.active)

      status = @user_query.active? ? "activated" : "deactivated"
      redirect_to admin_user_query_path(@user_query),
                  notice: "User query was successfully #{status}."
    end

    def validate
      query = params[:query]
      validator = UserQueryValidator.new(query)

      respond_to do |format|
        format.json do
          render json: {
            valid: validator.valid?,
            errors: validator.error_messages
          }
        end
      end
    end

    private

    def set_user_query
      @user_query = UserQuery.find(params[:id])
    end

    def user_query_params
      params.require(:user_query).permit(
        :name,
        :description,
        :query,
        :variable_definitions,
        :max_execution_time_ms,
        :active,
      )
    end
  end
end
