class BlocksController < ApplicationController
  before_action :set_block, only: %i[show edit update destroy]

  after_action :verify_authorized

  # GET /blocks
  # GET /blocks.json
  def index
    authorize Block
    @blocks = Block.order("index_position ASC")
  end

  # GET /blocks/1
  # GET /blocks/1.json
  def show
    authorize @block
  end

  # GET /blocks/new
  def new
    authorize Block
    @block = Block.new
  end

  # GET /blocks/1/edit
  def edit
    authorize @block
  end

  # POST /blocks
  # POST /blocks.json
  def create
    authorize Block
    @block = Block.new(permitted_attributes(Block))
    @block.user_id = current_user.id
    respond_to do |format|
      if @block.save
        format.html { redirect_to @block, notice: "Block was successfully created." }
        format.json { render :show, status: :created, location: @block }
      else
        format.html { render :new }
        format.json { render json: @block.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /blocks/1
  # PATCH/PUT /blocks/1.json
  def update
    authorize @block
    respond_to do |format|
      if @block.update(permitted_attributes(@block))
        @block.publish! if permitted_attributes(@block)[:publish_now]
        format.html { redirect_to @block, notice: "Block was successfully updated." }
        format.json { render :show, status: :ok, location: @block }
      else
        format.html { render :edit }
        format.json { render json: @block.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /blocks/1
  # DELETE /blocks/1.json
  def destroy
    authorize @block
    @block.destroy
    respond_to do |format|
      format.html { redirect_to blocks_url, notice: "Block was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_block
    @block = Block.find(params[:id])
  end
end
