require 'bundler/setup'
require 'flipper'

logging = Flipper[:logging]

perform_test = lambda do |number|
  logging.enable_percentage_of_time number

  total = 100_000
  enabled = []
  disabled = []

  enabled = (1..total).map { |n|
    logging.enabled? ? true : nil
  }.compact

  actual = (enabled.size / total.to_f * 100).round(3)

  # puts "#{enabled.size} / #{total}"
  puts "percentage: #{actual.to_s.rjust(6, ' ')} vs #{number.to_s.rjust(3, ' ')}"
end

puts "percentage: Actual vs Hoped For"

[0.001, 0.01, 0.1, 1, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 95, 99, 100].each do |number|
  perform_test.call number
end
