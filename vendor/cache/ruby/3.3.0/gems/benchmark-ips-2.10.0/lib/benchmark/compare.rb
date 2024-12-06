# encoding: utf-8

module Benchmark
  # Functionality of performaing comparison between reports.
  #
  # Usage:
  #
  # Add +x.compare!+ to perform comparison between reports.
  #
  # Example:
  #   > Benchmark.ips do |x|
  #     x.report('Reduce using tag')     { [*1..10].reduce(:+) }
  #     x.report('Reduce using to_proc') { [*1..10].reduce(&:+) }
  #     x.compare!
  #   end
  #
  #   Calculating -------------------------------------
  #       Reduce using tag     19216 i/100ms
  #   Reduce using to_proc     17437 i/100ms
  #   -------------------------------------------------
  #       Reduce using tag   278950.0 (±8.5%) i/s -    1402768 in   5.065112s
  #   Reduce using to_proc   247295.4 (±8.0%) i/s -    1238027 in   5.037299s
  #
  #   Comparison:
  #       Reduce using tag:   278950.0 i/s
  #   Reduce using to_proc:   247295.4 i/s - 1.13x slower
  #
  # Besides regular Calculating report, this will also indicates which one is slower.
  #
  # +x.compare!+ also takes an +order: :baseline+ option.
  #
  # Example:
  #  > Benchmark.ips do |x|
  #   x.report('Reduce using block')   { [*1..10].reduce { |sum, n| sum + n } }
  #   x.report('Reduce using tag')     { [*1..10].reduce(:+) }
  #   x.report('Reduce using to_proc') { [*1..10].reduce(&:+) }
  #   x.compare!(order: :baseline)
  # end
  #
  # Calculating -------------------------------------
  #   Reduce using block    886.202k (± 2.2%) i/s -      4.521M in   5.103774s
  #     Reduce using tag      1.821M (± 1.6%) i/s -      9.111M in   5.004183s
  # Reduce using to_proc    895.948k (± 1.6%) i/s -      4.528M in   5.055368s
  #
  # Comparison:
  #   Reduce using block:   886202.5 i/s
  #     Reduce using tag:  1821055.0 i/s - 2.05x  (± 0.00) faster
  # Reduce using to_proc:   895948.1 i/s - same-ish: difference falls within error
  #
  # The first report is considered the baseline against which other reports are compared.
  module Compare

    # Compare between reports, prints out facts of each report:
    # runtime, comparative speed difference.
    # @param entries [Array<Report::Entry>] Reports to compare.
    def compare(*entries, order: :fastest)
      return if entries.size < 2

      case order
      when :baseline
        baseline = entries.shift
        sorted = entries.sort_by{ |e| e.stats.central_tendency }.reverse
      when :fastest
        sorted = entries.sort_by{ |e| e.stats.central_tendency }.reverse
        baseline = sorted.shift
      else
        raise ArgumentError, "Unknwon order: #{order.inspect}"
      end

      $stdout.puts "\nComparison:"

      $stdout.printf "%20s: %10.1f i/s\n", baseline.label.to_s, baseline.stats.central_tendency

      sorted.each do |report|
        name = report.label.to_s

        $stdout.printf "%20s: %10.1f i/s - ", name, report.stats.central_tendency

        if report.stats.overlaps?(baseline.stats)
          $stdout.print "same-ish: difference falls within error"
        elsif report.stats.central_tendency > baseline.stats.central_tendency
          speedup, error = report.stats.speedup(baseline.stats)
          $stdout.printf "%.2fx ", speedup
          if error
            $stdout.printf " (± %.2f)", error
          end
          $stdout.print " faster"
        else
          slowdown, error = report.stats.slowdown(baseline.stats)
          $stdout.printf "%.2fx ", slowdown
          if error
            $stdout.printf " (± %.2f)", error
          end
          $stdout.print " slower"
        end

        $stdout.puts
      end

      footer = baseline.stats.footer
      $stdout.puts footer.rjust(40) if footer

      $stdout.puts
    end
  end

  extend Benchmark::Compare
end
