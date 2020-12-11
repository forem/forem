module RSpec
  module Core
    module Ordering
      RSpec.describe Identity do
        it "does not affect the ordering of the items" do
          expect(Identity.new.order([1, 2, 3])).to eq([1, 2, 3])
        end
      end

      RSpec.describe Random do
        describe '.order' do
          subject { described_class.new(configuration) }

          def item(n)
            instance_double(Example, :id => "./some_spec.rb[1:#{n}]")
          end

          let(:configuration)  { RSpec::Core::Configuration.new }
          let(:items)          { 10.times.map { |n| item(n) } }
          let(:shuffled_items) { subject.order items }

          it 'shuffles the items randomly' do
            expect(shuffled_items).to match_array items
            expect(shuffled_items).to_not eq items
          end

          context 'given multiple calls' do
            it 'returns the items in the same order' do
              expect(subject.order(items)).to eq shuffled_items
            end
          end

          def order_with(seed)
            configuration.seed = seed
            subject.order(items)
          end

          it 'has a good distribution', :slow do
            orderings = 1.upto(1000).map do |seed|
              order_with(seed)
            end.uniq

            # Here we are making sure that our hash function used for  ordering has a
            # good distribution. Each seed produces a deterministic order and we want
            # 99%+ of 1000 to be different.
            expect(orderings.count).to be > 990
          end

          context "when given a subset of a list that was previously shuffled with the same seed" do
            it "orders that subset the same as it was ordered before" do
              all_items = 20.times.map { |n| item(n) }

              all_shuffled = subject.order(all_items)
              expect(all_shuffled).not_to eq(all_items)

              last_half = all_items[10, 10]
              last_half_shuffled = subject.order(last_half)
              last_half_from_all_shuffled = all_shuffled.select { |i| last_half.include?(i) }

              expect(last_half_from_all_shuffled.map(&:id)).to eq(last_half_shuffled.map(&:id))
            end
          end

          context 'given randomization has been seeded explicitly' do
            before { @seed = srand }
            after  { srand @seed }

            it "does not affect the global random number generator" do
              srand 123
              val1, val2 = rand(1_000), rand(1_000)

              subject

              srand 123
              subject.order items
              expect(rand(1_000)).to eq(val1)
              subject.order items
              expect(rand(1_000)).to eq(val2)
            end
          end
        end
      end

      RSpec.describe RecentlyModified do
        before do
          allow(File).to receive(:mtime).with('./file_1.rb').and_return(::Time.new)
          allow(File).to receive(:mtime).with('./file_2.rb').and_return(::Time.new + 1)
        end

        it 'orders list by file modification time' do
          file_1 = instance_double(Example, :metadata => { :absolute_file_path => './file_1.rb' })
          file_2 = instance_double(Example, :metadata => { :absolute_file_path => './file_2.rb' })
          strategy = RecentlyModified.new

          expect(strategy.order([file_1, file_2])).to eq([file_2, file_1])
        end
      end

      RSpec.describe Custom do
        it 'uses the block to order the list' do
          strategy = Custom.new(proc { |list| list.reverse })

          expect(strategy.order([1, 2, 3, 4])).to eq([4, 3, 2, 1])
        end
      end

      RSpec.describe Registry do
        let(:configuration) { Configuration.new }
        subject(:registry) { Registry.new(configuration) }

        describe "#used_random_seed?" do
          it 'returns false if the random orderer has not been used' do
            expect(registry.used_random_seed?).to be false
          end

          it 'returns false if the random orderer has been fetched but not used' do
            expect(registry.fetch(:random)).to be_a(Random)
            expect(registry.used_random_seed?).to be false
          end

          it 'returns true if the random orderer has been used' do
            registry.fetch(:random).order([RSpec.describe, RSpec.describe])
            expect(registry.used_random_seed?).to be true
          end
        end

        describe "#fetch" do
          it "gives the registered ordering when called with a symbol" do
            ordering = Object.new
            subject.register(:falcon, ordering)

            expect(subject.fetch(:falcon)).to be ordering
          end

          context "when given an unrecognized symbol" do
            it 'invokes the given block and returns its value' do
              expect(subject.fetch(:falcon) { :fallback }).to eq(:fallback)
            end

            it 'raises an error if no block is given' do
              expect {
                subject.fetch(:falcon)
              }.to raise_error(IndexError)
            end
          end
        end
      end
    end
  end
end
