class HexComparer

  attr_accessor :hexes
  def initialize(hexes)
    @hexes = hexes
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

  def accent
    if brightness(1.14).size == 7
      brightness(1.14)
    elsif brightness(1.08).size == 7
      brightness(1.08)
    elsif brightness(1.06).size == 7
      brightness(1.06)
    elsif brightness(0.96).size == 7
      brightness(0.96)
    elsif brightness(0.9).size == 7
      brightness(0.9)
    elsif brightness(0.8).size == 7
      brightness(0.8)
    elsif brightness(0.7).size == 7
      brightness(0.7)
    elsif brightness(0.6).size == 7
      brightness(0.6)
    end
  end
  
end
