class BlocksController < ApplicationController
  before_action :set_block, only: [:show, :edit, :update, :destroy]

  before_action :require_super_admin

  # GET /blocks
  # GET /blocks.json
  def index
    @blocks = Block.order("index_position ASC")
  end

  # GET /blocks/1
  # GET /blocks/1.json
  def show
  end

  # GET /blocks/new
  def new
    @block = Block.new
  end

  # GET /blocks/1/edit
  def edit
  end

  # POST /blocks
  # POST /blocks.json
  def create
    @block = Block.new(block_params)
    @block.user_id = current_user.id
    respond_to do |format|
      if @block.save
        format.html { redirect_to @block, notice: 'Block was successfully created.' }
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
    respond_to do |format|
      if @block.update(block_params)
        if block_params[:publish_now]
          @block.publish!
        end
        format.html { redirect_to @block, notice: 'Block was successfully updated.' }
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
    @block.destroy
    respond_to do |format|
      format.html { redirect_to blocks_url, notice: 'Block was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_block
      @block = Block.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def block_params
      params.require(:block).permit(:input_html,
                                      :input_css,
                                      :input_javascript,
                                      :featured,
                                      :index_position,
                                      :publish_now)
    end
end
