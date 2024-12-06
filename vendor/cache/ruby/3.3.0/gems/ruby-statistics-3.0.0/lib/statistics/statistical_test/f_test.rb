module Statistics
  module StatisticalTest
    class FTest
      # This method calculates the one-way ANOVA F-test statistic.
      # We assume that all specified arguments are arrays.
      # It returns an array with three elements:
      #   [F-statistic or F-score, degrees of freedom numerator, degrees of freedom denominator].
      #
      # Formulas extracted from:
      # https://courses.lumenlearning.com/boundless-statistics/chapter/one-way-anova/
      # http://sphweb.bumc.bu.edu/otlt/MPH-Modules/BS/BS704_HypothesisTesting-ANOVA/BS704_HypothesisTesting-Anova_print.html
      def self.anova_f_score(*args)
        # If only two groups have been specified as arguments, we follow the classic F-Test for
        # equality of variances, which is the ratio between the variances.
        f_score = nil
        df1 = nil
        df2 = nil

        if args.size == 2
          variances = [args[0].variance, args[1].variance]

          f_score = variances.max/variances.min.to_r
          df1 = 1 # k-1 (k = 2)
          df2 = args.flatten.size - 2 # N-k (k = 2)
        elsif args.size > 2
          total_groups = args.size
          total_elements = args.flatten.size
          overall_mean = args.flatten.mean

          sample_sizes = args.map(&:size)
          sample_means = args.map(&:mean)
          sample_stds = args.map(&:standard_deviation)

          # Variance between groups
          iterator = sample_sizes.each_with_index

          variance_between_groups = iterator.reduce(0) do |summation, (size, index)|
            inner_calculation = size * ((sample_means[index] - overall_mean) ** 2)

            summation += (inner_calculation / (total_groups - 1).to_r)
          end

          # Variance within groups
          variance_within_groups = (0...total_groups).reduce(0) do |outer_summation, group_index|
            outer_summation += args[group_index].reduce(0) do |inner_sumation, observation|
              inner_calculation = ((observation - sample_means[group_index]) ** 2)
              inner_sumation += (inner_calculation / (total_elements - total_groups).to_r)
            end
          end

          f_score = variance_between_groups/variance_within_groups.to_r
          df1 = total_groups - 1
          df2 = total_elements - total_groups
        end

        [f_score, df1, df2]
      end

      # This method expects the alpha value and the groups to calculate the one-way ANOVA test.
      # It returns a hash with multiple information and the test result (if reject the null hypotesis or not).
      # Keep in mind that the values for the alternative key (true/false) does not imply that the alternative hypothesis
      # is TRUE or FALSE. It's a minor notation advantage to decide if reject the null hypothesis or not.

      def self.one_way_anova(alpha, *args)
        f_score, df1, df2 = *self.anova_f_score(*args) # Splat array result

        return if f_score.nil? || df1.nil? || df2.nil?

        probability = Distribution::F.new(df1, df2).cumulative_function(f_score)
        p_value = 1 - probability

        # According to https://stats.stackexchange.com/questions/29158/do-you-reject-the-null-hypothesis-when-p-alpha-or-p-leq-alpha
        # We can assume that if p_value <= alpha, we can safely reject the null hypothesis, ie. accept the alternative hypothesis.
        { probability: probability,
          p_value: p_value,
          alpha: alpha,
          null: alpha < p_value,
          alternative: p_value <= alpha,
          confidence_level: 1 - alpha }
      end
    end
  end
end
