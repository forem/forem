require 'benchmark/ips'
require 'rspec/support'
require 'rspec/support/with_keywords_when_needed'

Klass = Class.new do
  def test(*args, **kwargs)
  end
end

def class_exec_args
  Klass.class_exec(:a, :b) { }
end

def klass_exec_args
  RSpec::Support::WithKeywordsWhenNeeded.class_exec(Klass, :a, :b) { }
end

def class_exec_kw_args
  Klass.class_exec(a: :b) { |a:| }
end

def klass_exec_kw_args
  RSpec::Support::WithKeywordsWhenNeeded.class_exec(Klass, a: :b) { |a:| }
end

Benchmark.ips do |x|
  x.report("class_exec(*args)          ") { class_exec_args }
  x.report("klass_exec(*args)          ") { klass_exec_args }
  x.report("class_exec(*args, **kwargs)") { class_exec_kw_args }
  x.report("klass_exec(*args, **kwargs)") { klass_exec_kw_args }
end

__END__

Calculating -------------------------------------
class_exec(*args)
                          5.555M (± 1.6%) i/s -     27.864M in   5.017682s
klass_exec(*args)
                        657.945k (± 4.6%) i/s -      3.315M in   5.051511s
class_exec(*args, **kwargs)
                          2.882M (± 3.3%) i/s -     14.555M in   5.056905s
klass_exec(*args, **kwargs)
                         52.710k (± 4.1%) i/s -    265.188k in   5.041218s
