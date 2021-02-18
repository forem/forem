Feature: `throw_symbol` matcher

  The `throw_symbol` matcher is used to specify that a block of code throws a symbol. The most
  basic form passes if any symbol is thrown:

    ```ruby
    expect { throw :foo }.to throw_symbol
    ```

  You'll often want to specify that a particular symbol is thrown:

    ```ruby
    expect { throw :foo }.to throw_symbol(:foo)
    ```

  If you care about the additional argument given to throw, you can specify that as well:

    ```ruby
    expect { throw :foo, 7 }.to throw_symbol(:foo, 7)
    ```

  Scenario: basic usage
    Given a file named "throw_symbol_matcher_spec.rb" with:
      """ruby
      RSpec.describe "throw" do
        specify { expect { throw :foo    }.to     throw_symbol }
        specify { expect { throw :bar, 7 }.to     throw_symbol }
        specify { expect { 5 + 5         }.not_to throw_symbol }

        # deliberate failures
        specify { expect { throw :foo    }.not_to throw_symbol }
        specify { expect { throw :bar, 7 }.not_to throw_symbol }
        specify { expect { 5 + 5         }.to     throw_symbol }
      end
      """
    When I run `rspec throw_symbol_matcher_spec.rb`
    Then the output should contain all of these:
      | 6 examples, 3 failures                      |
      | expected no Symbol to be thrown, got :foo   |
      | expected no Symbol to be thrown, got :bar   |
      | expected a Symbol to be thrown, got nothing |

  Scenario: specify thrown symbol
    Given a file named "throw_symbol_matcher_spec.rb" with:
      """ruby
      RSpec.describe "throw symbol" do
        specify { expect { throw :foo    }.to     throw_symbol(:foo) }
        specify { expect { throw :foo, 7 }.to     throw_symbol(:foo) }
        specify { expect { 5 + 5         }.not_to throw_symbol(:foo) }
        specify { expect { throw :bar    }.not_to throw_symbol(:foo) }

        # deliberate failures
        specify { expect { throw :foo    }.not_to throw_symbol(:foo) }
        specify { expect { throw :foo, 7 }.not_to throw_symbol(:foo) }
        specify { expect { 5 + 5         }.to     throw_symbol(:foo) }
        specify { expect { throw :bar    }.to     throw_symbol(:foo) }
      end
      """
    When I run `rspec throw_symbol_matcher_spec.rb`
    Then the output should contain all of these:
      | 8 examples, 4 failures                          |
      | expected :foo not to be thrown, got :foo        |
      | expected :foo not to be thrown, got :foo with 7 |
      | expected :foo to be thrown, got nothing         |
      | expected :foo to be thrown, got :bar            |

  Scenario: specify thrown symbol and argument
    Given a file named "throw_symbol_argument_matcher_spec.rb" with:
      """ruby
      RSpec.describe "throw symbol with argument" do
        specify { expect { throw :foo, 7 }.to     throw_symbol(:foo, 7) }
        specify { expect { throw :foo, 8 }.not_to throw_symbol(:foo, 7) }
        specify { expect { throw :bar, 7 }.not_to throw_symbol(:foo, 7) }
        specify { expect { throw :foo    }.not_to throw_symbol(:foo, 7) }

        # deliberate failures
        specify { expect { throw :foo, 7 }.not_to throw_symbol(:foo, 7) }
        specify { expect { throw :foo, 8 }.to     throw_symbol(:foo, 7) }
        specify { expect { throw :bar, 7 }.to     throw_symbol(:foo, 7) }
        specify { expect { throw :foo    }.to     throw_symbol(:foo, 7) }
      end
      """
    When I run `rspec throw_symbol_argument_matcher_spec.rb`
    Then the output should contain all of these:
      | 8 examples, 4 failures                                       |
      | expected :foo with 7 not to be thrown, got :foo with 7       |
      | expected :foo with 7 to be thrown, got :foo with 8           |
      | expected :foo with 7 to be thrown, got :bar                  |
      | expected :foo with 7 to be thrown, got :foo with no argument |

