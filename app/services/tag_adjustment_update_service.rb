class TagAdjustmentUpdateService
  def initialize(tag_adjustment, tag_adjustment_params)
    @tag_adjustment = tag_adjustment
    @tag_adjustment_params = tag_adjustment_params
  end

  def update
    @tag_adjustment.update(@tag_adjustment_params)
  end
end
