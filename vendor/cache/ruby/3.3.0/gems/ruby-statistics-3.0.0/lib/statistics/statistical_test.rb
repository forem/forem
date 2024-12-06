Dir[File.dirname(__FILE__) + '/statistical_test/**/*.rb'].each {|file| require file }

module Statistics
  module StatisticalTest
  end
end

# If StatisticalTest is not defined, setup alias.
if defined?(Statistics) && !(defined?(StatisticalTest))
  StatisticalTest = Statistics::StatisticalTest
end
