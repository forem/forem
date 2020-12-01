Feature: `respond_to` matcher

  Use the `respond_to` matcher to specify details of an object's interface. In its most basic form:

    ```ruby
    expect(obj).to respond_to(:foo) # pass if obj.respond_to?(:foo)
    ```

  You can specify that an object responds to multiple messages in a single statement with
  multiple arguments passed to the matcher:

    ```ruby
    expect(obj).to respond_to(:foo, :bar) # passes if obj.respond_to?(:foo) && obj.respond_to?(:bar)
    ```

  If the number of arguments accepted by the method is important to you, you can specify
  that as well:

    ```ruby
    expect(obj).to respond_to(:foo).with(1).argument
    expect(obj).to respond_to(:bar).with(2).arguments
    expect(obj).to respond_to(:baz).with(1..2).arguments
    expect(obj).to respond_to(:xyz).with_unlimited_arguments
    ```

  If your Ruby version supports keyword arguments, you can specify a list of keywords accepted
  by the method.

    ```ruby
    expect(obj).to respond_to(:foo).with_keywords(:ichi, :ni)
    expect(obj).to respond_to(:bar).with(2).arguments.and_keywords(:san, :yon)
    expect(obj).to respond_to(:baz).with_arbitrary_keywords
    ```

  Note that this matcher relies entirely upon `#respond_to?`.  If an object dynamically responds
  to a message via `#method_missing`, but does not indicate this via `#respond_to?`, then this
  matcher will give you false results.

  Scenario: basic usage
    Given a file named "respond_to_matcher_spec.rb" with:
      """ruby
      RSpec.describe "a string" do
        it { is_expected.to respond_to(:length) }
        it { is_expected.to respond_to(:hash, :class, :to_s) }
        it { is_expected.not_to respond_to(:to_model) }
        it { is_expected.not_to respond_to(:compact, :flatten) }

        # deliberate failures
        it { is_expected.to respond_to(:to_model) }
        it { is_expected.to respond_to(:compact, :flatten) }
        it { is_expected.not_to respond_to(:length) }
        it { is_expected.not_to respond_to(:hash, :class, :to_s) }

        # mixed examples--String responds to :length but not :flatten
        # both specs should fail
        it { is_expected.to respond_to(:length, :flatten) }
        it { is_expected.not_to respond_to(:length, :flatten) }
      end
      """
    When I run `rspec respond_to_matcher_spec.rb`
    Then the output should contain all of these:
      | 10 examples, 6 failures                                    |
      | expected "a string" to respond to :to_model                |
      | expected "a string" to respond to :compact, :flatten       |
      | expected "a string" not to respond to :length              |
      | expected "a string" not to respond to :hash, :class, :to_s |
      | expected "a string" to respond to :flatten                 |
      | expected "a string" not to respond to :length              |

  Scenario: specify arguments
    Given a file named "respond_to_matcher_argument_checking_spec.rb" with:
      """ruby
      RSpec.describe 7 do
        it { is_expected.to respond_to(:zero?).with(0).arguments }
        it { is_expected.not_to respond_to(:zero?).with(1).argument }

        it { is_expected.to respond_to(:between?).with(2).arguments }
        it { is_expected.not_to respond_to(:between?).with(7).arguments }

        # deliberate failures
        it { is_expected.to respond_to(:zero?).with(1).argument }
        it { is_expected.not_to respond_to(:zero?).with(0).arguments }

        it { is_expected.to respond_to(:between?).with(7).arguments }
        it { is_expected.not_to respond_to(:between?).with(2).arguments }
      end
      """
    When I run `rspec respond_to_matcher_argument_checking_spec.rb`
    Then the output should contain all of these:
      | 8 examples, 4 failures                                  |
      | expected 7 to respond to :zero? with 1 argument         |
      | expected 7 not to respond to :zero? with 0 arguments    |
      | expected 7 to respond to :between? with 7 arguments     |
      | expected 7 not to respond to :between? with 2 arguments |

  @skip-when-splat-args-unsupported
  Scenario: specify arguments range
    Given a file named "respond_to_matcher_argument_range_checking_spec.rb" with:
      """ruby
      class MyClass
        def build(name, options = {})
        end

        def inspect
          'my_object'
        end
      end

      RSpec.describe MyClass do
        it { is_expected.to respond_to(:build).with(1..2).arguments }
        it { is_expected.not_to respond_to(:build).with(0..1).arguments }
        it { is_expected.not_to respond_to(:build).with(2..3).arguments }
        it { is_expected.not_to respond_to(:build).with(0..3).arguments }

        # deliberate failures
        it { is_expected.not_to respond_to(:build).with(1..2).arguments }
        it { is_expected.to respond_to(:build).with(0..1).arguments }
        it { is_expected.to respond_to(:build).with(2..3).arguments }
        it { is_expected.to respond_to(:build).with(0..3).arguments }
      end
      """
    When I run `rspec respond_to_matcher_argument_range_checking_spec.rb`
    Then the output should contain all of these:
      | 8 examples, 4 failures                                          |
      | expected my_object not to respond to :build with 1..2 arguments |
      | expected my_object to respond to :build with 0..1 arguments     |
      | expected my_object to respond to :build with 2..3 arguments     |
      | expected my_object to respond to :build with 0..3 arguments     |

  @skip-when-splat-args-unsupported
  Scenario: specify unlimited arguments
  Given a file named "respond_to_matcher_unlimited_argument_checking_spec.rb" with:
      """ruby
      class MyClass
        def greet(message = 'Hello', *people)
        end

        def hail(person)
        end

        def inspect
          'my_object'
        end
      end

      RSpec.describe MyClass do
        it { is_expected.to respond_to(:greet).with_unlimited_arguments }
        it { is_expected.to respond_to(:greet).with(1).argument.and_unlimited_arguments }
        it { is_expected.not_to respond_to(:hail).with_unlimited_arguments }
        it { is_expected.not_to respond_to(:hail).with(1).argument.and_unlimited_arguments }

        # deliberate failures
        it { is_expected.not_to respond_to(:greet).with_unlimited_arguments }
        it { is_expected.not_to respond_to(:greet).with(1).argument.and_unlimited_arguments }
        it { is_expected.to respond_to(:hail).with_unlimited_arguments }
        it { is_expected.to respond_to(:hail).with(1).argument.and_unlimited_arguments }
      end
      """
    When I run `rspec respond_to_matcher_unlimited_argument_checking_spec.rb`
    Then the output should contain all of these:
      | 8 examples, 4 failures                                                              |
      | expected my_object not to respond to :greet with unlimited arguments                |
      | expected my_object not to respond to :greet with 1 argument and unlimited arguments |
      | expected my_object to respond to :hail with unlimited arguments                     |
      | expected my_object to respond to :hail with 1 argument and unlimited arguments      |

  @skip-when-keyword-args-unsupported
  Scenario: specify keywords
    Given a file named "respond_to_matcher_keyword_checking_spec.rb" with:
      """ruby
      class MyClass
        def find(name = 'id', limit: 1_000, offset: 0)
          []
        end

        def inspect
          'my_object'
        end
      end

      RSpec.describe MyClass do
        it { is_expected.to respond_to(:find).with_keywords(:limit, :offset) }
        it { is_expected.to respond_to(:find).with(1).argument.and_keywords(:limit, :offset) }

        it { is_expected.not_to respond_to(:find).with_keywords(:limit, :offset, :page) }
        it { is_expected.not_to respond_to(:find).with(1).argument.and_keywords(:limit, :offset, :page) }

        # deliberate failures
        it { is_expected.to respond_to(:find).with_keywords(:limit, :offset, :page) }
        it { is_expected.to respond_to(:find).with(1).argument.and_keywords(:limit, :offset, :page) }

        it { is_expected.not_to respond_to(:find).with_keywords(:limit, :offset) }
        it { is_expected.not_to respond_to(:find).with(1).argument.and_keywords(:limit, :offset) }
      end
      """
    When I run `rspec respond_to_matcher_keyword_checking_spec.rb`
    Then the output should contain all of these:
      | 8 examples, 4 failures                                                                         |
      | expected my_object to respond to :find with keywords :limit, :offset, and :page                |
      | expected my_object to respond to :find with 1 argument and keywords :limit, :offset, and :page |
      | expected my_object not to respond to :find with keywords :limit and :offset                    |
      | expected my_object not to respond to :find with 1 argument and keywords :limit and :offset     |

  @skip-when-keyword-args-unsupported
  Scenario: specify any keywords
    Given a file named "respond_to_matcher_any_keywords_checking_spec.rb" with:
      """ruby
      class MyClass
        def build(name: 'object', **opts)
        end

        def create(name: 'object', type: String)
        end

        def inspect
          'my_object'
        end
      end

      RSpec.describe MyClass do
        it { is_expected.to respond_to(:build).with_any_keywords }
        it { is_expected.to respond_to(:build).with_keywords(:name).and_any_keywords }
        it { is_expected.not_to respond_to(:create).with_any_keywords }
        it { is_expected.not_to respond_to(:create).with_keywords(:name).and_any_keywords }

        # deliberate failures
        it { is_expected.not_to respond_to(:build).with_any_keywords }
        it { is_expected.not_to respond_to(:build).with_keywords(:name).and_any_keywords }
        it { is_expected.to respond_to(:create).with_any_keywords }
        it { is_expected.to respond_to(:create).with_keywords(:name).and_any_keywords }
      end
      """
    When I run `rspec respond_to_matcher_any_keywords_checking_spec.rb`
    Then the output should contain all of these:
      | 8 examples, 4 failures                                          |
      | expected my_object not to respond to :build with any keywords |
      | expected my_object not to respond to :build with keyword :name and any keywords |
      | expected my_object to respond to :create with any keywords |
      | expected my_object to respond to :create with keyword :name and any keywords |

  @skip-when-required-keyword-args-unsupported
  Scenario: specify required keywords
    Given a file named "respond_to_matcher_required_keyword_checking_spec.rb" with:
      """ruby
      class MyClass
        def plant(seed:, fertilizer: nil, water: 'daily')
          []
        end

        def inspect
          'my_object'
        end
      end

      RSpec.describe MyClass do
        it { is_expected.to respond_to(:plant).with_keywords(:seed) }
        it { is_expected.to respond_to(:plant).with_keywords(:seed, :fertilizer, :water) }
        it { is_expected.not_to respond_to(:plant).with_keywords(:fertilizer, :water) }

        # deliberate failures
        it { is_expected.not_to respond_to(:plant).with_keywords(:seed) }
        it { is_expected.not_to respond_to(:plant).with_keywords(:seed, :fertilizer, :water) }
        it { is_expected.to respond_to(:plant).with_keywords(:fertilizer, :water) }
      end
      """
    When I run `rspec respond_to_matcher_required_keyword_checking_spec.rb`
    Then the output should contain all of these:
      | 6 examples, 3 failures                                                                   |
      | expected my_object not to respond to :plant with keyword :seed                           |
      | expected my_object not to respond to :plant with keywords :seed, :fertilizer, and :water |
      | expected my_object to respond to :plant with keywords :fertilizer and :water             |
