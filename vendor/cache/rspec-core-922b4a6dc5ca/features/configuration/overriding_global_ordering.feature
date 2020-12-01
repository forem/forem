Feature: Overriding global ordering

  You can customize how RSpec orders examples and example groups. For an
  individual group, you can control it by tagging it with `:order` metadata:

    * `:defined` runs the examples (and sub groups) in defined order
    * `:random` runs them in random order

  If you have more specialized needs, you can register your own ordering using
  the `register_ordering` configuration option. If you register an ordering as
  `:global`, it will be the global default, used by all groups that do not have
  `:order` metadata (and by RSpec to order the top-level groups).

  Scenario: Running a specific example group in order
    Given a file named "order_dependent_spec.rb" with:
      """ruby
      RSpec.describe "examples only pass when they are run in order", :order => :defined do
        before(:context) { @list = [] }

        it "passes when run first" do
          @list << 1
          expect(@list).to eq([1])
        end

        it "passes when run second" do
          @list << 2
          expect(@list).to eq([1, 2])
        end

        it "passes when run third" do
          @list << 3
          expect(@list).to eq([1, 2, 3])
        end
      end
      """
    When I run `rspec order_dependent_spec.rb --order random:1`
    Then the examples should all pass

  Scenario: Registering a custom ordering
    Given a file named "register_custom_ordering_spec.rb" with:
      """ruby
      RSpec.configure do |rspec|
        rspec.register_ordering(:reverse) do |items|
          items.reverse
        end
      end

      RSpec.describe "A group that must run in reverse order", :order => :reverse do
        before(:context) { @list = [] }

        it "passes when run second" do
          @list << 2
          expect(@list).to eq([1, 2])
        end

        it "passes when run first" do
          @list << 1
          expect(@list).to eq([1])
        end
      end
      """
    When I run `rspec register_custom_ordering_spec.rb`
    Then the examples should all pass

  Scenario: Using a custom global ordering
    Given a file named "register_global_ordering_spec.rb" with:
      """ruby
      RSpec.configure do |rspec|
        rspec.register_ordering(:global) do |items|
          items.reverse
        end
      end

      RSpec.describe "A group without :order metadata" do
        before(:context) { @list = [] }

        it "passes when run second" do
          @list << 2
          expect(@list).to eq([1, 2])
        end

        it "passes when run first" do
          @list << 1
          expect(@list).to eq([1])
        end
      end
      """
    When I run `rspec register_global_ordering_spec.rb`
    Then the examples should all pass

