# TODO: Avoid monkey-patching.
module Enumerable
  def mean
    self.reduce(:+) / self.length.to_f
  end

  def variance
    mean = self.mean
    self.reduce(0) { |memo, value| memo + ((value - mean) ** 2) } / (self.length - 1).to_f
  end

  def standard_deviation
    Math.sqrt(self.variance)
  end
end
