class TagAdjustmentUpdateService
  def initialize(tag_adjustment, tag_adjustment_params)
    @tag_adjustment = tag_adjustment
    @tag_adjustment_params = tag_adjustment_params
  end

  def update
    @tag_adjustment.update(@tag_adjustment_params)
    # Overall incomplete
    # We don't yet need this but will.
    # Not supporting update of notification functionality yet
  end
end
