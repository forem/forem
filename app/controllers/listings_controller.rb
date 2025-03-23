class ListingsController < ApplicationController
  def index
    render json: []
  end

  def new
    render json: {}, status: :ok
  end

  def edit
    render json: {}, status: :ok
  end

  def dashboard
    render json: {}, status: :ok
  end

  def create
    render json: {}, status: :created
  end

  def update
    render json: {}, status: :ok
  end

  def delete_confirm
    render json: {}, status: :ok
  end

  def destroy
    respond_to do |format|
      format.json { render json: {}, status: :no_content } # Changed from head to render with empty JSON
    end
  end
end