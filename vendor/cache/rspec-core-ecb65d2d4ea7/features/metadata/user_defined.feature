Feature: User-defined metadata

  You can attach user-defined metadata to any example group or example. Pass a
  hash as the last argument (before the block) to `describe`, `context` or `it`.
  RSpec supports many configuration options that apply only to certain examples
  or groups based on the metadata.

  Metadata defined on an example group is available (and can be overridden) by
  any sub-group or from any example in that group or a sub-group.

  In addition, you can specify metadata using just symbols. Each symbol passed
  as an argument to `describe`, `context` or `it` will be a key in the metadata
  hash, with a corresponding value of `true`.

  Scenario: Define group metadata using a hash
    Given a file named "define_group_metadata_with_hash_spec.rb" with:
      """ruby
      RSpec.describe "a group with user-defined metadata", :foo => 17 do
        it 'has access to the metadata in the example' do |example|
          expect(example.metadata[:foo]).to eq(17)
        end

        it 'does not have access to metadata defined on sub-groups' do |example|
          expect(example.metadata).not_to include(:bar)
        end

        describe 'a sub-group with user-defined metadata', :bar => 12 do
          it 'has access to the sub-group metadata' do |example|
            expect(example.metadata[:bar]).to eq(12)
          end

          it 'also has access to metadata defined on parent groups' do |example|
            expect(example.metadata[:foo]).to eq(17)
          end
        end
      end
      """
    When I run `rspec define_group_metadata_with_hash_spec.rb`
    Then the examples should all pass

  Scenario: Define example metadata using a hash
    Given a file named "define_example_metadata_with_hash_spec.rb" with:
      """ruby
      RSpec.describe "a group with no user-defined metadata" do
        it 'has an example with metadata', :foo => 17 do |example|
          expect(example.metadata[:foo]).to eq(17)
          expect(example.metadata).not_to include(:bar)
        end

        it 'has another example with metadata', :bar => 12, :bazz => 33 do |example|
          expect(example.metadata[:bar]).to eq(12)
          expect(example.metadata[:bazz]).to eq(33)
          expect(example.metadata).not_to include(:foo)
        end
      end
      """
    When I run `rspec define_example_metadata_with_hash_spec.rb`
    Then the examples should all pass

  Scenario: Override user-defined metadata
    Given a file named "override_metadata_spec.rb" with:
      """ruby
      RSpec.describe "a group with user-defined metadata", :foo => 'bar' do
        it 'can be overridden by an example', :foo => 'bazz' do |example|
          expect(example.metadata[:foo]).to eq('bazz')
        end

        describe "a sub-group with an override", :foo => 'goo' do
          it 'can be overridden by a sub-group' do |example|
            expect(example.metadata[:foo]).to eq('goo')
          end
        end
      end
      """
    When I run `rspec override_metadata_spec.rb`
    Then the examples should all pass

  Scenario: Less verbose metadata
    Given a file named "less_verbose_metadata_spec.rb" with:
      """ruby
      RSpec.describe "a group with simple metadata", :fast, :simple, :bug => 73 do
        it 'has `:fast => true` metadata' do |example|
          expect(example.metadata[:fast]).to eq(true)
        end

        it 'has `:simple => true` metadata' do |example|
          expect(example.metadata[:simple]).to eq(true)
        end

        it 'can still use a hash for metadata' do |example|
          expect(example.metadata[:bug]).to eq(73)
        end

        it 'can define simple metadata on an example', :special do |example|
          expect(example.metadata[:special]).to eq(true)
        end
      end
      """
    When I run `rspec less_verbose_metadata_spec.rb`
    Then the examples should all pass
