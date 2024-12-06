# Some classes used in measurement tests
class Allocator
  def make_arrays
    10.times {|i| Array.new}
  end

  def make_hashes
    Hash.new
    Hash.new
    Hash.new
    Hash.new
    Hash.new
  end

  def make_strings
    a_string = 'a'
    b_string = a_string * 100
    String.new(b_string)
  end

  def run
    make_arrays
    make_hashes
    make_strings
  end
end
