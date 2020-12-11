module RSpec
  module Core
    RSpec.describe FilterableItemRepository, "#items_for" do
      FilterableItem = Struct.new(:name)

      def self.it_behaves_like_a_filterable_item_repo(&when_the_repo_has_items_with_metadata)
        let(:repo)   { described_class.new(:any?) }
        let(:item_1) { FilterableItem.new("Item 1") }
        let(:item_2) { FilterableItem.new("Item 2") }
        let(:item_3) { FilterableItem.new("Item 3") }
        let(:item_4) { FilterableItem.new("Item 4") }

        context "when the repository is empty" do
          it 'returns an empty list' do
            expect(repo.items_for(:foo => "bar")).to eq([])
          end
        end

        shared_examples_for "adding items to the repository" do |add_method|
          describe "adding items using `#{add_method}`" do
            define_method :add_item do |*args|
              repo.__send__ add_method, *args
            end

            context "when the repository has items that have no metadata" do
              before do
                add_item item_1, {}
                add_item item_2, {}
              end

              it "returns those items, regardless of the provided argument" do
                expect(repo.items_for({})).to contain_exactly(item_1, item_2)
                expect(repo.items_for(:foo => "bar")).to contain_exactly(item_1, item_2)
              end
            end

            context "when the repository has items that have metadata" do
              before do
                add_item item_1, :foo => "bar"
                add_item item_2, :slow => true
                add_item item_3, :foo => "bar"
              end

              it 'return an empty list when given empty metadata' do
                expect(repo.items_for({})).to eq([])
              end

              it 'return an empty list when given metadata that matches no items' do
                expect(repo.items_for(:slow => false, :foo => "bazz")).to eq([])
              end

              it 'returns matching items for the provided metadata' do
                expect(repo.items_for(:slow => true)).to contain_exactly(item_2)
                expect(repo.items_for(:foo => "bar")).to contain_exactly(item_1, item_3)
                expect(repo.items_for(:slow => true, :foo => "bar")).to contain_exactly(item_1, item_2, item_3)
              end

              it 'returns the matching items in the correct order' do
                expect(repo.items_for(:slow => true, :foo => "bar")).to eq items_in_expected_order
              end

              it 'ignores other metadata keys that are not related to the appended items' do
                expect(repo.items_for(:slow => true, :other => "foo")).to contain_exactly(item_2)
              end

              it 'differentiates between an applicable key being missing and having an explicit `nil` value' do
                add_item item_4, :bar => nil

                expect(repo.items_for({})).to eq([])
                expect(repo.items_for(:bar => nil)).to contain_exactly(item_4)
              end

              it 'returns the correct items when they are appended after a memoized lookup' do
                expect {
                  add_item item_4, :slow => true
                }.to change { repo.items_for(:slow => true) }.
                  from(a_collection_containing_exactly(item_2)).
                  to(a_collection_containing_exactly(item_2, item_4))
              end

              let(:flip_proc) do
                return_val = true
                Proc.new { return_val.tap { |v| return_val = !v } }
              end

              context "with proc values" do
                before do
                  add_item item_4, { :include_it => flip_proc }
                end

                it 'evaluates the proc each time since the logic can return a different value each time' do
                  expect(repo.items_for(:include_it => nil)).to contain_exactly(item_4)
                  expect(repo.items_for(:include_it => nil)).to eq([])
                  expect(repo.items_for(:include_it => nil)).to contain_exactly(item_4)
                  expect(repo.items_for(:include_it => nil)).to eq([])
                end
              end

              context "when initialized with the `:any?` predicate" do
                let(:repo) { FilterableItemRepository::QueryOptimized.new(:any?) }

                it 'matches against multi-entry items when any of the metadata entries match' do
                  add_item item_4, :key_1 => "val_1", :key_2 => "val_2"

                  expect(repo.items_for(:key_1 => "val_1")).to contain_exactly(item_4)
                  expect(repo.items_for(:key_2 => "val_2")).to contain_exactly(item_4)
                  expect(repo.items_for(:key_1 => "val_1", :key_2 => "val_2")).to contain_exactly(item_4)
                end
              end

              context "when initialized with the `:all?` predicate" do
                let(:repo) { FilterableItemRepository::QueryOptimized.new(:all?) }

                it 'matches against multi-entry items when all of the metadata entries match' do
                  add_item item_4, :key_1 => "val_1", :key_2 => "val_2"

                  expect(repo.items_for(:key_1 => "val_1")).to eq([])
                  expect(repo.items_for(:key_2 => "val_2")).to eq([])
                  expect(repo.items_for(:key_1 => "val_1", :key_2 => "val_2")).to contain_exactly(item_4)
                end
              end

              module_eval(&when_the_repo_has_items_with_metadata) if when_the_repo_has_items_with_metadata
            end
          end
        end

        it_behaves_like "adding items to the repository", :append do
          let(:items_in_expected_order) { [item_1, item_2, item_3] }
        end

        it_behaves_like "adding items to the repository", :prepend do
          let(:items_in_expected_order) { [item_3, item_2, item_1] }
        end

        describe '#delete' do
          before do
            repo.append item_1, {}
            repo.append item_1, :foo => true
            repo.append item_1, :foo => true, :bar => true
            repo.append item_2, :foo => true
          end

          it 'deletes the specified item with the metadata' do
            expect { repo.delete(item_1, :foo => true) }.
              to change { repo.items_and_filters }.
                from([
                  [item_1, {}],
                  [item_1, { :foo => true }],
                  [item_1, { :foo => true, :bar => true }],
                  [item_2, { :foo => true }]
                ]).
                to([
                  [item_1, {}],
                  [item_1, { :foo => true, :bar => true }],
                  [item_2, { :foo => true }]
                ]).
              and change { repo.items_for({ :foo => true }) }.
                from([item_1, item_1, item_1, item_2]).
                to([item_1, item_1, item_2]).
              and change { repo.items_for({ :foo => true, :bar => true }) }.
                from([item_1, item_1, item_1, item_2]).
                to([item_1, item_1, item_2]).
              and avoid_changing { repo.items_for({}) }.
                from([item_1])
          end
        end
      end

      describe FilterableItemRepository::UpdateOptimized do
        it_behaves_like_a_filterable_item_repo
      end

      describe FilterableItemRepository::QueryOptimized do
        it_behaves_like_a_filterable_item_repo do
          describe "performance optimization" do
            # NOTE: the specs in this context are potentially brittle because they are
            # coupled to the implementation's usage of `MetadataFilter.apply?`. However,
            # they demonstrate the perf optimization that was the reason we created
            # this class, and thus have value in demonstrating the memoization is working
            # properly and in documenting the reason the class exists in the first place.
            # Still, if these prove to be brittle in the future, feel free to delete them since
            # they are not concerned with externally visible behaviors.

            it 'is optimized to check metadata filter application for a given pair of metadata hashes only once' do
              # TODO: use mock expectations for this once https://github.com/rspec/rspec-mocks/pull/841 is fixed.
              call_counts = track_metadata_filter_apply_calls

              3.times do
                expect(repo.items_for(:slow => true, :other => "foo")).to contain_exactly(item_2)
              end

              expect(call_counts[:slow => true]).to eq(1)
            end

            it 'ignores extraneous metadata keys when doing memoized lookups' do
              # TODO: use mock expectations for this once https://github.com/rspec/rspec-mocks/pull/841 is fixed.
              call_counts = track_metadata_filter_apply_calls

              expect(repo.items_for(:slow => true, :other => "foo")).to contain_exactly(item_2)
              expect(repo.items_for(:slow => true, :other => "bar")).to contain_exactly(item_2)
              expect(repo.items_for(:slow => true, :goo => "bazz")).to contain_exactly(item_2)

              expect(call_counts[:slow => true]).to eq(1)
            end

            context "when there are some proc keys" do
              before do
                add_item item_4, { :include_it => flip_proc }
              end

              it 'still performs memoization for metadata hashes that lack those keys' do
                call_counts = track_metadata_filter_apply_calls

                expect(repo.items_for(:slow => true, :other => "foo")).to contain_exactly(item_2)
                expect(repo.items_for(:slow => true, :other => "foo")).to contain_exactly(item_2)

                expect(call_counts[:slow => true]).to eq(1)
              end
            end

            def track_metadata_filter_apply_calls
              Hash.new(0).tap do |call_counts|
                allow(MetadataFilter).to receive(:apply?).and_wrap_original do |original, predicate, item_meta, request_meta|
                  call_counts[item_meta] += 1
                  original.call(predicate, item_meta, request_meta)
                end
              end
            end
          end
        end
      end
    end
  end
end
