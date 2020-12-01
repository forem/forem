require 'benchmark/ips'

metadata = { :file_path => "some/path.rb" }
meta_with_absolute = metadata.merge(:absolute_file_path => File.expand_path(metadata[:file_path]))

Benchmark.ips do |x|
  x.report("fetch absolute path from hash") do
    meta_with_absolute[:absolute_file_path]
  end

  x.report("calculate absolute path") do
    File.expand_path(metadata[:file_path])
  end
end

__END__

Precalculating the absolute file path is much, much faster!

Calculating -------------------------------------
fetch absolute path from hash
                       102.164k i/100ms
calculate absolute path
                         9.331k i/100ms
-------------------------------------------------
fetch absolute path from hash
                          7.091M (±11.6%) i/s -     34.736M
calculate absolute path
                        113.141k (± 8.6%) i/s -    569.191k
