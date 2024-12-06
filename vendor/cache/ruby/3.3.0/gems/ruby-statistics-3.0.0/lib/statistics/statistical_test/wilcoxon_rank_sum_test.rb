module Statistics
  module StatisticalTest
    class WilcoxonRankSumTest
      def rank(elements)
        ranked_elements = {}

        elements.sort.each_with_index do |element, index|
          if ranked_elements.fetch(element, false)
            # This allow us to solve the ties easily when performing the rank summation per group
            ranked_elements[element][:counter] += 1
            ranked_elements[element][:rank] += (index + 1)
          else
            ranked_elements[element] = { counter: 1, rank: (index + 1) }
          end
        end

        # ranked_elements = [{ x => { counter: 1, rank: y } ]
        ranked_elements
      end

      # Steps to perform the calculation are based on http://www.mit.edu/~6.s085/notes/lecture5.pdf
      def perform(alpha, tails, group_one, group_two)
        # Size for each group
        n1, n2 = group_one.size, group_two.size

        # Rank all data
        total_ranks = rank(group_one + group_two)

        # sum rankings per group
        r1 = ranked_sum_for(total_ranks, group_one)
        r2 = ranked_sum_for(total_ranks, group_two)

        # calculate U statistic
        u1 = (n1 * (n1 + 1)/2.0) - r1
        u2 = (n2 * (n2 + 1)/2.0 ) - r2

        u_statistic = [u1.abs, u2.abs].min

        median_u = (n1 * n2)/2.0

        ties = total_ranks.values.select { |element| element[:counter] > 1 }

        std_u = if ties.size > 0
                  corrected_sigma(ties, n1, n2)
                else
                  Math.sqrt((n1 * n2 * (n1 + n2 + 1))/12.0)
                end

        z = (u_statistic - median_u)/std_u

        # Most literature are not very specific about the normal distribution to be used.
        # We ran multiple tests with a Normal(median_u, std_u) and Normal(0, 1) and we found
        # the latter to be more aligned with the results.
        probability = Distribution::StandardNormal.new.cumulative_function(z.abs)
        p_value = 1 - probability
        p_value *= 2 if tails == :two_tail

        { probability: probability,
          u: u_statistic,
          z: z,
          p_value: p_value,
          alpha: alpha,
          null: alpha < p_value,
          alternative: p_value <= alpha,
          confidence_level: 1 - alpha }
      end

      # Formula extracted from http://www.statstutor.ac.uk/resources/uploaded/mannwhitney.pdf
      private def corrected_sigma(ties, total_group_one, total_group_two)
        n = total_group_one + total_group_two

        rank_sum = ties.reduce(0) do |memo, t|
                    memo += ((t[:counter] ** 3) - t[:counter])/12.0
                  end

        left = (total_group_one * total_group_two)/(n * (n - 1)).to_r
        right = (((n ** 3) - n)/12.0) - rank_sum

        Math.sqrt(left * right)
      end

      private def ranked_sum_for(total, group)
        # sum rankings per group
        group.reduce(0) do |memo, element|
          rank_of_element = total[element][:rank] / total[element][:counter].to_r
          memo += rank_of_element
        end
      end
    end

    # Both test are the same. To keep the selected name, we just alias the class
    # with the implementation.
    MannWhitneyU = WilcoxonRankSumTest
  end
end
