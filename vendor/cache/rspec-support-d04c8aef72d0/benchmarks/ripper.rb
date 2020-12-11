require 'benchmark/ips'
require 'ripper'

ruby_version = defined?(JRUBY_VERSION) ? JRUBY_VERSION : RUBY_VERSION
puts "#{RUBY_ENGINE} #{ruby_version}"

source = File.read(__FILE__)

Benchmark.ips do |x|
  x.report("Ripper") do
    Ripper.sexp(source)
    Ripper.lex(source)
  end
end

__END__

ruby 1.9.3
Calculating -------------------------------------
              Ripper   284.000  i/100ms

ruby 2.2.3
Calculating -------------------------------------
              Ripper   320.000  i/100ms

jruby 1.7.5
Calculating -------------------------------------
              Ripper    24.000  i/100ms

jruby 1.7.13
Calculating -------------------------------------
              Ripper    25.000  i/100ms

jruby 1.7.14
Calculating -------------------------------------
              Ripper   239.000  i/100ms

jruby 1.7.22
Calculating -------------------------------------
              Ripper   231.000  i/100ms

jruby 9.0.1.0
Calculating -------------------------------------
              Ripper   218.000  i/100ms
