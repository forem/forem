require "mini_histogram/version"

# A class for building histogram info
#
# Given an array, this class calculates the "edges" of a histogram
# these edges mark the boundries for "bins"
#
#   array = [1,1,1, 5, 5, 5, 5, 10, 10, 10]
#   histogram = MiniHistogram.new(array)
#   puts histogram.edges
#   # => [0.0, 2.0, 4.0, 6.0, 8.0, 10.0, 12.0]
#
# It also finds the weights (aka count of values) that would go in each bin:
#
#   puts histogram.weights
#   # => [3, 0, 4, 0, 0, 3]
#
# This means that the `array` here had three items between 0.0 and 2.0.
#
class MiniHistogram
  class Error < StandardError; end
  attr_reader :array, :left_p, :max

  def initialize(array, left_p: true, edges: nil)
    @array = array
    @left_p = left_p
    @edges = edges
    @weights = nil

    @min, @max = array.minmax
  end

  def edges_min
    edges.min
  end

  def edges_max
    edges.max
  end

  def histogram(*_)
    self
  end

  def closed
    @left_p ? :left : :right
  end

  # Sets the edge value to something new,
  # also clears any previously calculated values
  def update_values(edges:, max: )
    @edges = edges
    @max = max
    @weights = nil # clear memoized value
  end

  def bin_size
    return 0 if edges.length <= 1

    edges[1] - edges[0]
  end

  # Weird name, right? There are multiple ways to
  # calculate the number of "bins" a histogram should have, one
  # of the most common is the "sturges" method
  #
  # Here are some alternatives from numpy:
  # https://github.com/numpy/numpy/blob/d9b1e32cb8ef90d6b4a47853241db2a28146a57d/numpy/lib/histograms.py#L489-L521
  def sturges
    len = array.length
    return 1.0 if len == 0

    # return (long)(ceil(Math.log2(n)) + 1);
    return Math.log2(len).ceil + 1
  end

  # Given an array of edges and an array we want to generate a histogram from
  # return the counts for each "bin"
  #
  # Example:
  #
  #   a = [1,1,1, 5, 5, 5, 5, 10, 10, 10]
  #   edges = [0.0, 2.0, 4.0, 6.0, 8.0, 10.0, 12.0]
  #
  #   MiniHistogram.new(a).weights
  #   # => [3, 0, 4, 0, 0, 3]
  #
  #   This means that the `a` array has 3 values between 0.0 and 2.0
  #   4 values between 4.0 and 6.0 and three values between 10.0 and 12.0
  def weights
    return @weights if @weights
    return @weights = [] if array.empty?

    lo = edges.first
    step = edges[1] - edges[0]

    max_index = ((@max  - lo) / step).floor
    @weights = Array.new(max_index + 1, 0)

    array.each do |x|
      index = ((x - lo) / step).floor
      @weights[index] += 1
    end

    return @weights
  end

  # Finds the "edges" of a given histogram that will mark the boundries
  # for the histogram's "bins"
  #
  # Example:
  #
  #  a = [1,1,1, 5, 5, 5, 5, 10, 10, 10]
  #  MiniHistogram.new(a).edges
  #  # => [0.0, 2.0, 4.0, 6.0, 8.0, 10.0, 12.0]
  #
  #  There are multiple ways to find edges, this was taken from
  #  https://github.com/mrkn/enumerable-statistics/issues/24
  #
  #  Another good set of implementations is in numpy
  #  https://github.com/numpy/numpy/blob/d9b1e32cb8ef90d6b4a47853241db2a28146a57d/numpy/lib/histograms.py#L222
  def edges
    return @edges if @edges

    return @edges = [0.0] if array.empty?

    lo = @min
    hi = @max

    nbins = sturges.to_f

    if hi == lo
      start = lo
      step = 1.0
      divisor = 1.0
      len = 1
    else
      bw = (hi - lo) / nbins
      lbw = Math.log10(bw)
      if lbw >= 0
        step = 10 ** lbw.floor * 1.0
        r = bw/step

        if r <= 1.1
          # do nothing
        elsif r <= 2.2
          step *= 2.0
        elsif r <= 5.5
          step *= 5.0
        else
          step *= 10
        end
        divisor = 1.0
        start = step * (lo/step).floor
        len = ((hi - start)/step).ceil
      else
        divisor = 10 ** - lbw.floor
        r = bw * divisor
        if r <= 1.1
          # do nothing
        elsif r <= 2.2
          divisor /= 2.0
        elsif r <= 5.5
          divisor /= 5.0
        else
          divisor /= 10.0
        end
        step = 1.0
        start = (lo * divisor).floor
        len = (hi * divisor - start).ceil
      end
    end

    if left_p
      while (lo < start/divisor)
        start -= step
      end

      while (start + (len - 1)*step)/divisor <= hi
        len += 1
      end
    else
      while lo <= start/divisor
        start -= step
      end
      while (start + (len - 1)*step)/divisor < hi
        len += 1
      end
    end

    @edges = []
    len.times.each do
      @edges << start/divisor
      start += step
    end

    return @edges
  end
  alias :edge :edges

  def plot
    raise "You must `require 'mini_histogram/plot'` to get this feature"
  end

  # Given an array of Histograms this function calcualtes
  # an average edge size along with the minimum and maximum
  # edge values. It then updates the edge value on all inputs
  #
  # The main pourpose of this method is to be able to chart multiple
  # distributions against a similar axis
  #
  # See for more context: https://github.com/schneems/derailed_benchmarks/pull/169
  def self.set_average_edges!(*array_of_histograms)
    array_of_histograms.each { |x| raise "Input expected to be a histogram but is #{x.inspect}" unless x.is_a?(MiniHistogram) }
    steps = array_of_histograms.map(&:bin_size)
    avg_step_size = steps.inject(&:+).to_f / steps.length

    max_value = array_of_histograms.map(&:max).max

    max_edge = array_of_histograms.map(&:edges_max).max
    min_edge = array_of_histograms.map(&:edges_min).min

    average_edges = [min_edge]
    while average_edges.last < max_edge
      average_edges << average_edges.last + avg_step_size
    end

    array_of_histograms.each {|h| h.update_values(edges: average_edges, max: max_value) }

    return array_of_histograms
  end
end

