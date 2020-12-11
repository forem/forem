require 'benchmark/ips'
require 'digest/md5'

MAX_32_BIT = 4294967295

def jenkins_iterative(string)
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

def jenkins_inject(string)
  hash = string.each_byte.inject(0) do |byte, hash|
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

require 'benchmark/ips'

Benchmark.ips do |x|
  x.report("md5") do
    Digest::MD5.digest("string")
  end

  x.report("jenkins iterative") do
    jenkins_iterative("string")
  end

  x.report("jenkins inject") do
    jenkins_inject("string")
  end

  x.compare!
end

__END__

Calculating -------------------------------------
                 md5    39.416k i/100ms
   jenkins iterative    22.646k i/100ms
      jenkins inject    18.271k i/100ms
-------------------------------------------------
                 md5    654.294k (±15.7%) i/s -      3.193M
   jenkins iterative    349.669k (±10.3%) i/s -      1.744M
      jenkins inject    286.774k (± 5.5%) i/s -      1.443M

Comparison:
                 md5:   654293.8 i/s
   jenkins iterative:   349668.8 i/s - 1.87x slower
      jenkins inject:   286774.4 i/s - 2.28x slower
