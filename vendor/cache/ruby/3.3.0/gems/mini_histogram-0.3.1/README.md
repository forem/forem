# MiniHistogram [![Build Status](https://travis-ci.org/zombocom/mini_histogram.svg?branch=master)](https://travis-ci.org/zombocom/mini_histogram)

What's a histogram and why should you care? First read [Lies, Damned Lies, and Averages: Perc50, Perc95 explained for Programmers](https://schneems.com/2020/03/17/lies-damned-lies-and-averages-perc50-perc95-explained-for-programmers/). This library lets you build histograms in pure Ruby.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'mini_histogram'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install mini_histogram

## Usage

Given an array, this class calculates the "edges" of a histogram these edges mark the boundries for "bins"

```ruby
array = [1,1,1, 5, 5, 5, 5, 10, 10, 10]
histogram = MiniHistogram.new(array)
puts histogram.edges
# => [0.0, 2.0, 4.0, 6.0, 8.0, 10.0, 12.0]
```

It also finds the weights (aka count of values) that would go in each bin:

```
puts histogram.weights
# => [3, 0, 4, 0, 0, 3]
```

This means that the `array` here had three items between 0.0 and 2.0, four items between 4.0 and 6.0 and three items between 10.0 and 12.0

## Plotting [experimental]

You can plot!

```ruby
require 'mini_histogram/plot'
array = 50.times.map { rand(11.2..11.6) }
histogram = MiniHistogram.new(array)
puts histogram.plot
```

Will generate:

```
                  ┌                                        ┐
   [11.2 , 11.25) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 9
   [11.25, 11.3 ) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 6
   [11.3 , 11.35) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇ 4
   [11.35, 11.4 ) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇ 4
   [11.4 , 11.45) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 11
   [11.45, 11.5 ) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 5
   [11.5 , 11.55) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 7
   [11.55, 11.6 ) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇ 4
                  └                                        ┘
                                  Frequency
```

Integrated plotting is an experimental currently, use with some caution. If you are on Ruby 2.4+ you can pass an instance of MiniHistogram to [unicode_plot.rb](https://github.com/red-data-tools/unicode_plot.rb):

```ruby
array = 50.times.map { rand(11.2..11.6) }
histogram = MiniHistogram.new(array)
puts UnicodePlot.histogram(histogram)
```

## Plotting dualing histograms [experimental]

If you're plotting multiple histograms (first, please normalize the bucket sizes), second. It can be hard to compare them vertically. Here's an example:

```
                  ┌                                        ┐
   [11.2 , 11.28) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 12
   [11.28, 11.36) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 22
   [11.35, 11.43) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 30
   [11.43, 11.51) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 17
   [11.5 , 11.58) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 13
   [11.58, 11.66) ┤▇▇▇▇▇▇▇ 6
   [11.65, 11.73) ┤ 0
   [11.73, 11.81) ┤ 0
   [11.8 , 11.88) ┤ 0
                  └                                        ┘
                                  Frequency
                  ┌                                        ┐
   [11.2 , 11.28) ┤▇▇▇▇ 3
   [11.28, 11.36) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 19
   [11.35, 11.43) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 17
   [11.43, 11.51) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 25
   [11.5 , 11.58) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 15
   [11.58, 11.66) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 13
   [11.65, 11.73) ┤▇▇▇▇ 3
   [11.73, 11.81) ┤▇▇▇▇ 3
   [11.8 , 11.88) ┤▇▇▇ 2
                  └                                        ┘
                                  Frequency
```

Here's the same data set plotted side-by-side:

```
                  ┌                                        ┐                    ┌                                        ┐
   [11.2 , 11.28) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 12                             [11.2 , 11.28) ┤▇▇▇▇ 3
   [11.28, 11.36) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 22                 [11.28, 11.36) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 19
   [11.35, 11.43) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 30       [11.35, 11.43) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 17
   [11.43, 11.51) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 17                       [11.43, 11.51) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 25
   [11.5 , 11.58) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 13                           [11.5 , 11.58) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 15
   [11.58, 11.66) ┤▇▇▇▇▇▇▇ 6                                     [11.58, 11.66) ┤▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇▇ 13
   [11.65, 11.73) ┤ 0                                            [11.65, 11.73) ┤▇▇▇▇ 3
   [11.73, 11.81) ┤ 0                                            [11.73, 11.81) ┤▇▇▇▇ 3
   [11.8 , 11.88) ┤ 0                                            [11.8 , 11.88) ┤▇▇▇ 2
                  └                                        ┘                    └                                        ┘
                                  Frequency                                                     Frequency
```

This method might require more scrolling in the github issue, but makes it easier to compare two distributions. Here's how you plot dualing histograms:

```ruby
require 'mini_histogram/plot'

a = MiniHistogram.new [11.205184, 11.223665, 11.228286, 11.23219, 11.233325, 11.234516, 11.245781, 11.248441, 11.250758, 11.255686, 11.265876, 11.26641, 11.279456, 11.281067, 11.284281, 11.287656, 11.289316, 11.289682, 11.292289, 11.294518, 11.296454, 11.299277, 11.305801, 11.306602, 11.309311, 11.318465, 11.318477, 11.322258, 11.328267, 11.334188, 11.339722, 11.340585, 11.346084, 11.346197, 11.351863, 11.35982, 11.362358, 11.364476, 11.365743, 11.368492, 11.368566, 11.36869, 11.37268, 11.374204, 11.374217, 11.374955, 11.376422, 11.377989, 11.383357, 11.383593, 11.385184, 11.394766, 11.395829, 11.398455, 11.399739, 11.401304, 11.411387, 11.411978, 11.413585, 11.413659, 11.418504, 11.419194, 11.419415, 11.421374, 11.4261, 11.427901, 11.429651, 11.434272, 11.435012, 11.440848, 11.447495, 11.456107, 11.457434, 11.467112, 11.471005, 11.473235, 11.485025, 11.485852, 11.488256, 11.488275, 11.499545, 11.509588, 11.51378, 11.51544, 11.520783, 11.52246, 11.522855, 11.5322, 11.533764, 11.544047, 11.552597, 11.558062, 11.567239, 11.569749, 11.575796, 11.588014, 11.614032, 11.615062, 11.618194, 11.635267]
b = MiniHistogram.new [11.233813, 11.240717, 11.254617, 11.282013, 11.290658, 11.303213, 11.305237, 11.305299, 11.306397, 11.313867, 11.31397, 11.314444, 11.318032, 11.328111, 11.330127, 11.333235, 11.33678, 11.337799, 11.343758, 11.347798, 11.347915, 11.349594, 11.358198, 11.358507, 11.3628, 11.366111, 11.374993, 11.378195, 11.38166, 11.384867, 11.385235, 11.395825, 11.404434, 11.406065, 11.406677, 11.410244, 11.414527, 11.421267, 11.424535, 11.427231, 11.427869, 11.428548, 11.432594, 11.433524, 11.434903, 11.437769, 11.439761, 11.443437, 11.443846, 11.451106, 11.458503, 11.462256, 11.462324, 11.464342, 11.464716, 11.46477, 11.465271, 11.466843, 11.468789, 11.475492, 11.488113, 11.489616, 11.493736, 11.496842, 11.502074, 11.511367, 11.512634, 11.515562, 11.525771, 11.531415, 11.535379, 11.53966, 11.540969, 11.541265, 11.541978, 11.545301, 11.545533, 11.545701, 11.572584, 11.578881, 11.580701, 11.580922, 11.588731, 11.594082, 11.595915, 11.613622, 11.619884, 11.632889, 11.64377, 11.645225, 11.647167, 11.648257, 11.667158, 11.670378, 11.681261, 11.734586, 11.747066, 11.792425, 11.808377, 11.812346]

dual_histogram = MiniHistogram.dual_plot do |x, y|
  x.histogram = a
  x.options = {}
  y.histogram = b
  y.options = {}
end
puts dual_histogram
```


## Alternatives

Alternatives to this gem include https://github.com/mrkn/enumerable-statistics/. I needed this gem to be able to calculate a "shared" or "average" edge value as seen in this PR https://github.com/mrkn/enumerable-statistics/pull/23. So that I could add histograms to derailed benchmarks: https://github.com/schneems/derailed_benchmarks/pull/169. This gem provides a `MiniHistogram.set_average_edges!` method to help there. Also this gem does not require a native extension compilation (faster to install, but performance is slower), and this gem does not extend or monkeypatch an core classes.

[MiniHistogram API Docs](https://rubydoc.info/github/zombocom/mini_histogram/master/MiniHistogram)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/zombocom/mini_histogram. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/zombocom/mini_histogram/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the MiniHistogram project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/zombocom/mini_histogram/blob/master/CODE_OF_CONDUCT.md).
