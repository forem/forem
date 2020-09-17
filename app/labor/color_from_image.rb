class ColorFromImage
  def initialize(url)
    @url = url
  end

  def main
    "#dddddd"
    # get_hex
  rescue StandardError
    "#dddddd"
  end

  def get_hex
    # colors = Miro::DominantColors.new @url
    HexComparer.new(colors.to_hex).biggest # Always take the biggest hex (aka lightest color)
  end
end
