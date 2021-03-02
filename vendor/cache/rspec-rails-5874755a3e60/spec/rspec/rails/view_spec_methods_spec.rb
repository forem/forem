module RSpec::Rails
  RSpec.describe ViewSpecMethods do
    before do
      class ::VCSampleClass; end
    end

    after do
      Object.send(:remove_const, :VCSampleClass)
    end

    describe ".add_extra_params_accessors_to" do
      describe "when accessors are not yet defined" do
        it "adds them as instance methods" do
          ViewSpecMethods.add_to(VCSampleClass)

          expect(VCSampleClass.instance_methods.map(&:to_sym)).to(include(:extra_params=))
          expect(VCSampleClass.instance_methods.map(&:to_sym)).to(include(:extra_params))
        end

        describe "the added #extra_params reader" do
          it "raises an error when a user tries to mutate it" do
            ViewSpecMethods.add_to(VCSampleClass)

            expect {
              VCSampleClass.new.extra_params[:id] = 4
            }.to raise_error(/can't modify frozen/)
          end
        end
      end

      describe "when accessors are already defined" do
        before do
          class ::VCSampleClass
            def extra_params; end

            def extra_params=; end
          end
        end

        it "does not redefine them" do
          ViewSpecMethods.add_to(VCSampleClass)
          expect(VCSampleClass.new.extra_params).to be_nil
        end
      end
    end

    describe ".remove_extra_params_accessors_from" do
      describe "when accessors are defined" do
        before do
          ViewSpecMethods.add_to(VCSampleClass)
        end

        it "removes them" do
          ViewSpecMethods.remove_from(VCSampleClass)

          expect(VCSampleClass.instance_methods).to_not include("extra_params=")
          expect(VCSampleClass.instance_methods).to_not include(:extra_params=)
          expect(VCSampleClass.instance_methods).to_not include("extra_params")
          expect(VCSampleClass.instance_methods).to_not include(:extra_params)
        end
      end

      describe "when accessors are not defined" do
        it "does nothing" do
          expect {
            ViewSpecMethods.remove_from(VCSampleClass)
          }.to_not change { VCSampleClass.instance_methods }
        end
      end
    end
  end
end
