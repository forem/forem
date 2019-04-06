class HexComparer
  def initialize(hexes, amount = 1)
    @hexes = hexes
    @amount = amount
  end

  def order
    hexes.sort
  end

  def smallest
    order.first
  end

  def biggest
    order.last
  end

  def brightness(amount = 1)
    rgb = smallest.delete("#").scan(/../).map(&:hex).map { |color| color * amount }.map(&:round)
    format("#%02x%02x%02x", *rgb)
  rescue StandardError
    smallest
  end

  def accent
    if brightness(1.14**amount).size == 7
      brightness(1.14**amount)
    elsif brightness(1.08**amount).size == 7
      brightness(1.08**amount)
    elsif brightness(1.06**amount).size == 7
      brightness(1.06**amount)
    elsif brightness(0.96**amount).size == 7
      brightness(0.96**amount)
    elsif brightness(0.9**amount).size == 7
      brightness(0.9**amount)
    elsif brightness(0.8**amount).size == 7
      brightness(0.8**amount)
    elsif brightness(0.7**amount).size == 7
      brightness(0.7**amount)
    elsif brightness(0.6**amount).size == 7
      brightness(0.6**amount)
    end
  end

  private

  attr_accessor :hexes, :amount
end
