module Statistics
  module StatisticalTest
    class KolmogorovSmirnovTest
      # Common alpha, and critical D are calculated following formulas from: https://en.wikipedia.org/wiki/Kolmogorov%E2%80%93Smirnov_test#Two-sample_Kolmogorov%E2%80%93Smirnov_test
      def self.two_samples(group_one:, group_two:, alpha: 0.05)
        samples = group_one + group_two # We can use unbalaced group samples

        ecdf_one = Distribution::Empirical.new(samples: group_one)
        ecdf_two = Distribution::Empirical.new(samples: group_two)

        d_max = samples.sort.map do |sample|
          d1 = ecdf_one.cumulative_function(x: sample)
          d2 = ecdf_two.cumulative_function(x: sample)

          (d1 - d2).abs
        end.max

        # TODO: Validate calculation of Common alpha.
        common_alpha = Math.sqrt((-0.5 * Math.log(alpha)))
        radicand = (group_one.size + group_two.size) / (group_one.size * group_two.size).to_r

        critical_d = common_alpha * Math.sqrt(radicand)
        # critical_d = self.critical_d(alpha: alpha, n: samples.size)

        # We are unable to calculate the p_value, because we don't have the Kolmogorov distribution
        # defined. We reject the null hypotesis if Dmax is > than Dcritical.
        { d_max: d_max,
          d_critical: critical_d,
          total_samples: samples.size,
          alpha: alpha,
          null: d_max <= critical_d,
          alternative: d_max > critical_d,
          confidence_level: 1.0 - alpha }
      end

      # This is an implementation of the formula presented by Paul Molin and Hervé Abdi in a paper,
      # called "New Table and numerical approximations for Kolmogorov-Smirnov / Lilliefors / Van Soest
      # normality test".
      # In this paper, the authors defines a couple of 6th-degree polynomial functions that allow us
      # to find an aproximation of the real critical value. This is based in the conclusions made by
      # Dagnelie (1968), where indicates that critical values given by Lilliefors can be approximated
      # numerically.
      #
      # In general, the formula found is:
      #  C(N, alpha) ^ -2  = A(alpha) * N + B(alpha).
      #
      # Where A(alpha), B(alpha) are two 6th degree polynomial functions computed using the principle
      # of Monte Carlo simulations.
      #
      # paper can be found here: https://utdallas.edu/~herve/MolinAbdi1998-LillieforsTechReport.pdf
      # def self.critical_d(alpha:, n:)
      #   confidence = 1.0 - alpha

      #   a_alpha = 6.32207539843126 -17.1398870006148 * confidence +
      #     38.42812675101057 * (confidence ** 2) - 45.93241384693391 * (confidence ** 3) +
      #     7.88697700041829 * (confidence ** 4) + 29.79317711037858 * (confidence ** 5) -
      #     18.48090137098585 * (confidence ** 6)

      #   b_alpha = 12.940399038404 - 53.458334259532 * confidence +
      #     186.923866119699 * (confidence ** 2) - 410.582178349305 * (confidence ** 3) +
      #     517.377862566267 * (confidence ** 4) - 343.581476222384 * (confidence ** 5) +
      #     92.123451358715 * (confidence ** 6)

      #   Math.sqrt(1.0 / (a_alpha * n + b_alpha))
      # end
    end

    KSTest = KolmogorovSmirnovTest # Alias
  end
end
