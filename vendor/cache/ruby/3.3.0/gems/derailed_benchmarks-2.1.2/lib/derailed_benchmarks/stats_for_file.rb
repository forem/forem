# frozen_string_literal: true

module DerailedBenchmarks
  # A class for reading in benchmark results
  # and converting them to numbers for comparison
  #
  # Example:
  #
  #  puts `cat muhfile.bench.txt`
  #
  #    9.590142   0.831269  10.457801 ( 10.0)
  #    9.836019   0.837319  10.728024 ( 11.0)
  #
  #  x = StatsForFile.new(name: "muhcommit", file: "muhfile.bench.txt", desc: "I made it faster", time: Time.now)
  #  x.values  #=> [11.437769, 11.792425]
  #  x.average # => 10.5
  #  x.name    # => "muhfile"
  class StatsForFile
    attr_reader :name, :values, :desc, :time, :short_sha

    def initialize(file:, name:, desc: "", time: , short_sha: nil)
      @file = Pathname.new(file)
      FileUtils.touch(@file)

      @name = name
      @desc = desc
      @time = time
      @short_sha = short_sha
    end

    def call
      load_file!
      return if values.empty?

      @median = (values[(values.length - 1) / 2] + values[values.length/ 2]) / 2.0
      @average = values.inject(:+) / values.length
    end

    def empty?
      values.empty?
    end

    def median
      @median.to_f
    end

    def average
      @average.to_f
    end

    private def load_file!
      @values = []
      @file.each_line do |line|
        line.match(/\( +(\d+\.\d+)\)/)
        begin
          values << BigDecimal($1)
        rescue => e
          raise e, "Problem with file #{@file.inspect}:\n#{@file.read}\n#{e.message}"
        end
      end

      values.sort!
      values.freeze
    end
  end
end
