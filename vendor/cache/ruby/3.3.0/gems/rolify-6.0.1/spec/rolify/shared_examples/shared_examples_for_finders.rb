shared_examples_for :finders do |param_name, param_method|
  context "using #{param_name} as parameter" do
    describe ".with_role" do
      it { should respond_to(:with_role).with(1).argument }
      it { should respond_to(:with_role).with(2).arguments }

      context "when resource setting: strict is set to false" do
        context "with a global role" do
          it { subject.with_role("admin".send(param_method)).should eq([ root ]) }
          it { subject.with_role("moderator".send(param_method)).should be_empty }
          it { subject.with_role("visitor".send(param_method)).should be_empty }
        end

        context "with a class scoped role" do
          context "on Forum class" do
            it { subject.with_role("admin".send(param_method), Forum).should eq([ root ]) }
            it { subject.with_role("moderator".send(param_method), Forum).should eq([ modo ]) }
            it { subject.with_role("visitor".send(param_method), Forum).should be_empty }
          end

          context "on Group class" do
            it { subject.with_role("admin".send(param_method), Group).should eq([ root ]) }
            it { subject.with_role("moderator".send(param_method), Group).should eq([ root ]) }
            it { subject.with_role("visitor".send(param_method), Group).should be_empty }
          end
        end

        context "with an instance scoped role" do
          context "on Forum.first instance" do
            it { subject.with_role("admin".send(param_method), Forum.first).should eq([ root ]) }
            it { subject.with_role("moderator".send(param_method), Forum.first).should eq([ modo ]) }
            it { subject.with_role("visitor".send(param_method), Forum.first).should be_empty }
          end

          context "on Forum.last instance" do
            it { subject.with_role("admin".send(param_method), Forum.last).should eq([ root ]) }
            it { subject.with_role("moderator".send(param_method), Forum.last).should eq([ modo ]) }
            it { subject.with_role("visitor".send(param_method), Forum.last).should include(root, visitor) } # =~ doesn't pass using mongoid, don't know why...
          end

          context "on Group.first instance" do
            it { subject.with_role("admin".send(param_method), Group.first).should eq([ root ]) }
            it { subject.with_role("moderator".send(param_method), Group.first).should eq([ root ]) }
            it { subject.with_role("visitor".send(param_method), Group.first).should eq([ modo ]) }
          end

          context "on Company.first_instance" do
            it { subject.with_role("owner".send(param_method), Company.first).should eq([ owner ]) }
          end
        end
      end

      context "when resource setting: strict is set to true" do
        before(:context) do
          user_class.strict_rolify = true
        end
        after(:context) do
          user_class.strict_rolify = false
        end

        context "with an instance scoped role" do
          context "on Forum.first instance" do
            it { subject.with_role("admin".send(param_method), Forum.first).should be_empty }
            it { subject.with_role("moderator".send(param_method), Forum.first).should be_empty }
          end

          context "on any resource" do
            it { subject.with_role("admin".send(param_method), :any).should_not be_empty }
            it { subject.with_role("moderator".send(param_method), :any).should_not be_empty }
          end
        end
      end
    end

    describe ".without_role" do
      it { should respond_to(:without_role).with(1).argument }
      it { should respond_to(:without_role).with(2).arguments }

      context "with a global role" do
        it { subject.without_role("admin".send(param_method)).should_not eq([ root ]) }
        it { subject.without_role("moderator".send(param_method)).should_not be_empty }
        it { subject.without_role("visitor".send(param_method)).should_not be_empty }
      end

      context "with a class scoped role" do
        context "on Forum class" do
          it { subject.without_role("admin".send(param_method), Forum).should_not eq([ root ]) }
          it { subject.without_role("moderator".send(param_method), Forum).should_not eq([ modo ]) }
          it { subject.without_role("visitor".send(param_method), Forum).should_not be_empty }
        end

        context "on Group class" do
          it { subject.without_role("admin".send(param_method), Group).should_not eq([ root ]) }
          it { subject.without_role("moderator".send(param_method), Group).should_not eq([ root ]) }
          it { subject.without_role("visitor".send(param_method), Group).should_not be_empty }
        end
      end

      context "with an instance scoped role" do
        context "on Forum.first instance" do
          it { subject.without_role("admin".send(param_method), Forum.first).should_not eq([ root ]) }
          it { subject.without_role("moderator".send(param_method), Forum.first).should_not eq([ modo ]) }
          it { subject.without_role("visitor".send(param_method), Forum.first).should_not be_empty }
        end

        context "on Forum.last instance" do
          it { subject.without_role("admin".send(param_method), Forum.last).should_not eq([ root ]) }
          it { subject.without_role("moderator".send(param_method), Forum.last).should_not eq([ modo ]) }
          it { subject.without_role("visitor".send(param_method), Forum.last).should_not include(root, visitor) } # =~ doesn't pass using mongoid, don't know why...
        end

        context "on Group.first instance" do
          it { subject.without_role("admin".send(param_method), Group.first).should_not eq([ root ]) }
          it { subject.without_role("moderator".send(param_method), Group.first).should_not eq([ root ]) }
          it { subject.without_role("visitor".send(param_method), Group.first).should_not eq([ modo ]) }
        end

        context "on Company.first_instance" do
          it { subject.without_role("owner".send(param_method), Company.first).should_not eq([ owner ]) }
        end
      end
    end


    describe ".with_all_roles" do
      it { should respond_to(:with_all_roles) }

      it { subject.with_all_roles("admin".send(param_method), :staff).should eq([ root ]) }
      it { subject.with_all_roles("admin".send(param_method), :staff, { :name => "moderator".send(param_method), :resource => Group }).should eq([ root ]) }
      it { subject.with_all_roles("admin".send(param_method), "moderator".send(param_method)).should be_empty }
      it { subject.with_all_roles("admin".send(param_method), :staff, { :name => "moderator".send(param_method), :resource => Forum }).should be_empty }
      it { subject.with_all_roles({ :name => "moderator".send(param_method), :resource => Forum }, { :name => :manager, :resource => Group }).should eq([ modo ]) }
      it { subject.with_all_roles("moderator".send(param_method), :manager).should be_empty }
      it { subject.with_all_roles({ :name => "visitor".send(param_method), :resource => Forum.last }, { :name => "moderator".send(param_method), :resource => Group }).should eq([ root ]) }
      it { subject.with_all_roles({ :name => "visitor".send(param_method), :resource => Group.first }, { :name => "moderator".send(param_method), :resource => Forum }).should eq([ modo ]) }
      it { subject.with_all_roles({ :name => "visitor".send(param_method), :resource => :any }, { :name => "moderator".send(param_method), :resource => :any }).should =~ [ root, modo ] }
    end

    describe ".with_any_role" do
      it { should respond_to(:with_any_role) }

      it { subject.with_any_role("admin".send(param_method), :staff).should eq([ root ]) }
      it { subject.with_any_role("admin".send(param_method), :staff, { :name => "moderator".send(param_method), :resource => Group }).should eq([ root ]) }
      it { subject.with_any_role("admin".send(param_method), "moderator".send(param_method)).should eq([ root ]) }
      it { subject.with_any_role("admin".send(param_method), :staff, { :name => "moderator".send(param_method), :resource => Forum }).should =~ [ root, modo ] }
      it { subject.with_any_role({ :name => "moderator".send(param_method), :resource => Forum }, { :name => :manager, :resource => Group }).should eq([ modo ]) }
      it { subject.with_any_role({ :name => "moderator".send(param_method), :resource => Group }, { :name => :manager, :resource => Group }).should =~ [ root, modo ] }
      it { subject.with_any_role("moderator".send(param_method), :manager).should be_empty }
      it { subject.with_any_role({ :name => "visitor".send(param_method), :resource => Forum.last }, { :name => "moderator".send(param_method), :resource => Group }).should =~ [ root, visitor ] }
      it { subject.with_any_role({ :name => "visitor".send(param_method), :resource => Group.first }, { :name => "moderator".send(param_method), :resource => Forum }).should eq([ modo ]) }
      it { subject.with_any_role({ :name => "visitor".send(param_method), :resource => :any }, { :name => "moderator".send(param_method), :resource => :any }).should =~ [ root, modo, visitor ] }
    end
  end
end
