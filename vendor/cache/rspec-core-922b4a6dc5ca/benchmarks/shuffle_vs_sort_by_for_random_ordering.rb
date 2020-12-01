require 'benchmark/ips'
require 'digest/md5'

class Digest::Jenkins
  MAX_32_BIT = 4294967295

  def self.digest(string)
    hash = 0

    string.each_byte do |byte|
      hash += byte
      hash &= MAX_32_BIT
      hash += ((hash << 10) & MAX_32_BIT)
      hash &= MAX_32_BIT
      hash ^= hash >> 6
    end

    hash += (hash << 3 & MAX_32_BIT)
    hash &= MAX_32_BIT
    hash ^= hash >> 11
    hash += (hash << 15 & MAX_32_BIT)
    hash &= MAX_32_BIT
    hash
  end
end

Example = Struct.new(:id)
$seed = Kernel.srand.to_s

def shuffle_list(list)
  list.shuffle
end

def sort_using_id(list)
  list.sort_by(&:id)
end

def sort_using_md5(list)
  list.sort_by { |item| Digest::MD5.digest($seed + item.id) }
end

def sort_using_jenkins(list)
  list.sort_by { |item| Digest::Jenkins.digest($seed + item.id) }
end

[10, 100, 1000, 10000].each do |size|
  puts "Size: #{size}"
  list = Array.new(size) { |i| Example.new("./some_spec.rb[1:#{i}]") }

  Benchmark.ips do |x|
    x.report("shuffle") { shuffle_list(list) }
    x.report("use id") { sort_using_id(list) }
    x.report("use md5") { sort_using_md5(list) }
    x.report("use jenkins") { sort_using_md5(list) }
    x.compare!
  end
end

__END__

Size: 10
Calculating -------------------------------------
             shuffle    71.860k i/100ms
              use id    22.562k i/100ms
             use md5     4.620k i/100ms
         use jenkins     4.644k i/100ms
-------------------------------------------------
             shuffle      1.594M (±12.4%) i/s -      7.905M
              use id    299.105k (± 7.1%) i/s -      1.489M
             use md5     49.663k (± 7.5%) i/s -    249.480k
         use jenkins     49.389k (± 7.5%) i/s -    246.132k

Comparison:
             shuffle:  1593820.8 i/s
              use id:   299104.9 i/s - 5.33x slower
             use md5:    49662.9 i/s - 32.09x slower
         use jenkins:    49389.2 i/s - 32.27x slower

Size: 100
Calculating -------------------------------------
             shuffle    24.629k i/100ms
              use id     2.076k i/100ms
             use md5   477.000  i/100ms
         use jenkins   483.000  i/100ms
-------------------------------------------------
             shuffle    317.269k (±13.8%) i/s -      1.576M
              use id     20.958k (± 4.2%) i/s -    105.876k
             use md5      4.916k (± 7.5%) i/s -     24.804k
         use jenkins      4.824k (± 8.6%) i/s -     24.150k

Comparison:
             shuffle:   317269.5 i/s
              use id:    20957.6 i/s - 15.14x slower
             use md5:     4916.5 i/s - 64.53x slower
         use jenkins:     4823.5 i/s - 65.78x slower

Size: 1000
Calculating -------------------------------------
             shuffle     3.862k i/100ms
              use id   134.000  i/100ms
             use md5    44.000  i/100ms
         use jenkins    44.000  i/100ms
-------------------------------------------------
             shuffle     40.104k (± 4.4%) i/s -    200.824k
              use id      1.424k (±13.5%) i/s -      6.968k
             use md5    450.556  (± 8.0%) i/s -      2.244k
         use jenkins    450.189  (± 7.6%) i/s -      2.244k

Comparison:
             shuffle:    40104.2 i/s
              use id:     1423.9 i/s - 28.16x slower
             use md5:      450.6 i/s - 89.01x slower
         use jenkins:      450.2 i/s - 89.08x slower

Size: 10000
Calculating -------------------------------------
             shuffle   374.000  i/100ms
              use id    10.000  i/100ms
             use md5     3.000  i/100ms
         use jenkins     4.000  i/100ms
-------------------------------------------------
             shuffle      3.750k (± 5.4%) i/s -     18.700k
              use id    109.008  (± 4.6%) i/s -    550.000
             use md5     40.614  (± 9.8%) i/s -    201.000
         use jenkins     39.975  (± 7.5%) i/s -    200.000

Comparison:
             shuffle:     3750.0 i/s
              use id:      109.0 i/s - 34.40x slower
             use md5:       40.6 i/s - 92.33x slower
         use jenkins:       40.0 i/s - 93.81x slower
