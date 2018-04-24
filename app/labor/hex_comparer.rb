class HexComparer

  attr_accessor :hexes, :amount
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
    begin
      rgb = smallest.gsub("#","").scan(/../).map(&:hex).map{ |color| color * amount }.map(&:round)
      "#%02x%02x%02x" % rgb
    rescue
      smallest
    end
  end

  def accent()
    if brightness(1.14 ** amount).size == 7
      brightness(1.14 ** amount)
    elsif brightness(1.08 ** amount).size == 7
      brightness(1.08 ** amount)
    elsif brightness(1.06 ** amount).size == 7
      brightness(1.06 ** amount)
    elsif brightness(0.96 ** amount).size == 7
      brightness(0.96 ** amount)
    elsif brightness(0.9 ** amount).size == 7
      brightness(0.9 ** amount)
    elsif brightness(0.8 ** amount).size == 7
      brightness(0.8 ** amount)
    elsif brightness(0.7 ** amount).size == 7
      brightness(0.7 ** amount)
    elsif brightness(0.6 ** amount).size == 7
      brightness(0.6 ** amount)
    end
  end
  
end
