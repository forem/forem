class ImageRateLimitError < StandardError
  def message
    "Too many upload attempts."
  end
end
