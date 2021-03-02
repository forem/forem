module RSpec::Rails
  RSpec.describe HelperExampleGroup do
    module ::FoosHelper
      class InternalClass
      end
    end

    subject { HelperExampleGroup }

    it_behaves_like "an rspec-rails example group mixin", :helper,
                    './spec/helpers/', '.\\spec\\helpers\\'

    it "provides a controller_path based on the helper module's name" do
      example = double
      allow(example).to receive_message_chain(:example_group, :described_class) { FoosHelper }

      helper_spec = Object.new.extend HelperExampleGroup
      expect(helper_spec.__send__(:_controller_path, example)).to eq("foos")
    end

    describe "#helper" do
      it "returns the instance of AV::Base provided by AV::TC::Behavior" do
        without_partial_double_verification do
          helper_spec = Object.new.extend HelperExampleGroup
          expect(helper_spec).to receive(:view_assigns)
          av_tc_b_view = double('_view')
          expect(av_tc_b_view).to receive(:assign)
          allow(helper_spec).to receive(:_view) { av_tc_b_view }
          expect(helper_spec.helper).to eq(av_tc_b_view)
        end
      end

      before do
        Object.const_set(:ApplicationHelper, Module.new)
      end

      after do
        Object.__send__(:remove_const, :ApplicationHelper)
      end

      it "includes ApplicationHelper" do
        group = RSpec::Core::ExampleGroup.describe do
          include HelperExampleGroup
          if ActionView::Base.respond_to?(:empty)
            def _view
              ActionView::Base.empty
            end
          else
            def _view
              ActionView::Base.new
            end
          end
        end
        expect(group.new.helper).to be_kind_of(ApplicationHelper)
      end
    end
  end

  RSpec.describe HelperExampleGroup::ClassMethods do
    describe "determine_default_helper_class" do
      let(:group) do
        RSpec::Core::ExampleGroup.describe do
          include HelperExampleGroup
        end
      end

      context "the described is a module" do
        it "returns the module" do
          allow(group).to receive(:described_class) { FoosHelper }
          expect(group.determine_default_helper_class("ignore this"))
            .to eq(FoosHelper)
        end
      end

      context "the described is a class" do
        it "returns nil" do
          allow(group).to receive(:described_class) { FoosHelper::InternalClass }
          expect(group.determine_default_helper_class("ignore this"))
            .to be_nil
        end
      end
    end
  end
end
