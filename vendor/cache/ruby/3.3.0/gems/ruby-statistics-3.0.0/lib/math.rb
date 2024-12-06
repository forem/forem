module Math
  def self.factorial(n)
    return if n < 0

    n = n.to_i # Only integers.

    return 1 if n == 0 || n == 1
    Math.gamma(n + 1) # Math.gamma(x) == (n - 1)! for integer values
  end

  def self.combination(n, r)
    self.factorial(n)/(self.factorial(r) * self.factorial(n - r)).to_r # n!/(r! * [n - r]!)
  end

  def self.permutation(n, k)
    self.factorial(n)/self.factorial(n - k).to_r
  end

  # Function adapted from the python implementation that exists in https://en.wikipedia.org/wiki/Simpson%27s_rule#Sample_implementation
  # Finite integral in the interval [a, b] split up in n-intervals
  def self.simpson_rule(a, b, n, &block)
    unless n.even?
      puts "The composite simpson's rule needs even intervals!"
      return
    end

    h = (b - a)/n.to_r

    resA = yield(a)
    resB = yield(b)

    sum = resA + resB

    (1..n).step(2).each do |number|
      res = yield(a + number * h)
      sum += 4 * res
    end

    (1..(n-1)).step(2).each do |number|
      res = yield(a + number * h)
      sum += 2 * res
    end

    return sum * h / 3.0
  end

  def self.lower_incomplete_gamma_function(s, x)
    # The greater the iterations, the better. That's why we are iterating 10_000 * x times
    self.simpson_rule(0, x.to_r, (10_000 * x.round).round) do |t|
      (t ** (s - 1)) * Math.exp(-t)
    end
  end

  def self.beta_function(x, y)
    return 1 if x == 1 && y == 1

    (Math.gamma(x) * Math.gamma(y))/Math.gamma(x + y)
  end

  ### This implementation is an adaptation of the incomplete beta function made in C by
  ### Lewis Van Winkle, which released the code under the zlib license.
  ### The whole math behind this code is described in the following post: https://codeplea.com/incomplete-beta-function-c
  def self.incomplete_beta_function(x, alp, bet)
    return if x < 0.0
    return 1.0 if x > 1.0

    tiny = 1.0E-50

    if x > ((alp + 1.0)/(alp + bet + 2.0))
      return 1.0 - self.incomplete_beta_function(1.0 - x, bet, alp)
    end

    # To avoid overflow problems, the implementation applies the logarithm properties
    # to calculate in a faster and safer way the values.
    lbet_ab = (Math.lgamma(alp)[0] + Math.lgamma(bet)[0] - Math.lgamma(alp + bet)[0]).freeze
    front = (Math.exp(Math.log(x) * alp + Math.log(1.0 - x) * bet - lbet_ab) / alp.to_r).freeze

    # This is the non-log version of the left part of the formula (before the continuous fraction)
    # down_left = alp * self.beta_function(alp, bet)
    # upper_left = (x ** alp) * ((1.0 - x) ** bet)
    # front = upper_left/down_left

    f, c, d = 1.0, 1.0, 0.0

    returned_value = nil

    # Let's do more iterations than the proposed implementation (200 iters)
    (0..500).each do |number|
      m = number/2

      numerator = if number == 0
                    1.0
                  elsif number % 2 == 0
                    (m * (bet - m) * x)/((alp + 2.0 * m - 1.0)* (alp + 2.0 * m))
                  else
                    top = -((alp + m) * (alp + bet + m) * x)
                    down = ((alp + 2.0 * m) * (alp + 2.0 * m + 1.0))

                    top/down
                  end

      d = 1.0 + numerator * d
      d = tiny if d.abs < tiny
      d = 1.0 / d

      c = 1.0 + numerator / c
      c = tiny if c.abs < tiny

      cd = (c*d).freeze
      f = f * cd


      if (1.0 - cd).abs < 1.0E-10
        returned_value = front * (f - 1.0)
        break
      end
    end

    returned_value
  end
end
