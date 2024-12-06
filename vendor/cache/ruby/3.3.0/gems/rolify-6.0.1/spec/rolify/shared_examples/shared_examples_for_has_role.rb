shared_examples_for "#has_role?_examples" do |param_name, param_method|
  context "using #{param_name} as parameter" do
    context "with a global role", :scope => :global do
      it { subject.has_role?("admin".send(param_method)).should be_truthy }

      it { subject.has_cached_role?("admin".send(param_method)).should be_truthy }

      context "on resource request" do
        it { subject.has_role?("admin".send(param_method), Forum.first).should be_truthy }
        it { subject.has_role?("admin".send(param_method), Forum).should be_truthy }
        it { subject.has_role?("admin".send(param_method), :any).should be_truthy }

        it { subject.has_cached_role?("admin".send(param_method), Forum.first).should be_truthy }
        it { subject.has_cached_role?("admin".send(param_method), Forum).should be_truthy }
        it { subject.has_cached_role?("admin".send(param_method), :any).should be_truthy }
      end

      context "with another global role" do
        before(:all) { role_class.create(:name => "global") }

        it { subject.has_role?("global".send(param_method)).should be_falsey }
        it { subject.has_role?("global".send(param_method), :any).should be_falsey }

        it { subject.has_cached_role?("global".send(param_method)).should be_falsey }
        it { subject.has_cached_role?("global".send(param_method), :any).should be_falsey }
      end

      it "should not get an instance scoped role" do
        subject.has_role?("moderator".send(param_method), Group.first).should be_falsey

        subject.has_cached_role?("moderator".send(param_method), Group.first).should be_falsey
      end

      it "should not get a class scoped role" do
        subject.has_role?("manager".send(param_method), Forum).should be_falsey

        subject.has_cached_role?("manager".send(param_method), Forum).should be_falsey
      end

      context "using inexisting role" do
        it { subject.has_role?("dummy".send(param_method)).should be_falsey }
        it { subject.has_role?("dumber".send(param_method), Forum.first).should be_falsey }

        it { subject.has_cached_role?("dummy".send(param_method)).should be_falsey }
        it { subject.has_cached_role?("dumber".send(param_method), Forum.first).should be_falsey }
      end
    end

    context "with a class scoped role", :scope => :class do
      context "on class scoped role request" do
        it { subject.has_role?("manager".send(param_method), Forum).should be_truthy }
        it { subject.has_role?("manager".send(param_method), Forum.first).should be_truthy }
        it { subject.has_role?("manager".send(param_method), :any).should be_truthy }

        it { subject.has_cached_role?("manager".send(param_method), Forum).should be_truthy }
        it { subject.has_cached_role?("manager".send(param_method), Forum.first).should be_truthy }
        it { subject.has_cached_role?("manager".send(param_method), :any).should be_truthy }
      end

      it "should not get a scoped role when asking for a global" do
        subject.has_role?("manager".send(param_method)).should be_falsey

        subject.has_cached_role?("manager".send(param_method)).should be_falsey
      end

      it "should not get a global role" do
        role_class.create(:name => "admin")
        subject.has_role?("admin".send(param_method)).should be_falsey

        subject.has_cached_role?("admin".send(param_method)).should be_falsey
      end

      context "with another class scoped role" do
        context "on the same resource but with a different name" do
          before(:all) { role_class.create(:name => "member", :resource_type => "Forum") }

          it { subject.has_role?("member".send(param_method), Forum).should be_falsey }
          it { subject.has_role?("member".send(param_method), :any).should be_falsey }

          it { subject.has_cached_role?("member".send(param_method), Forum).should be_falsey }
          it { subject.has_cached_role?("member".send(param_method), :any).should be_falsey }
        end

        context "on another resource with the same name" do
          before(:all) { role_class.create(:name => "manager", :resource_type => "Group") }

          it { subject.has_role?("manager".send(param_method), Group).should be_falsey }
          it { subject.has_role?("manager".send(param_method), :any).should be_truthy }

          it { subject.has_cached_role?("manager".send(param_method), Group).should be_falsey }
          it { subject.has_cached_role?("manager".send(param_method), :any).should be_truthy }
        end

        context "on another resource with another name" do
          before(:all) { role_class.create(:name => "defenders", :resource_type => "Group") }

          it { subject.has_role?("defenders".send(param_method), Group).should be_falsey }
          it { subject.has_role?("defenders".send(param_method), :any).should be_falsey }

          it { subject.has_cached_role?("defenders".send(param_method), Group).should be_falsey }
          it { subject.has_cached_role?("defenders".send(param_method), :any).should be_falsey }
        end
      end

      context "using inexisting role" do
        it { subject.has_role?("dummy".send(param_method), Forum).should be_falsey }
        it { subject.has_role?("dumber".send(param_method)).should be_falsey }

        it { subject.has_cached_role?("dummy".send(param_method), Forum).should be_falsey }
        it { subject.has_cached_role?("dumber".send(param_method)).should be_falsey }
      end
    end

    context "with a instance scoped role", :scope => :instance do
      context "on instance scoped role request" do
        it { subject.has_role?("moderator".send(param_method), Forum.first).should be_truthy }
        it { subject.has_role?("moderator".send(param_method), :any).should be_truthy }
        it {
          m = subject.class.new
          m.add_role("moderator", Forum.first)
          m.has_role?("moderator".send(param_method), :any).should be_truthy
        }

        it { subject.has_cached_role?("moderator".send(param_method), Forum.first).should be_truthy }
        it { subject.has_cached_role?("moderator".send(param_method), :any).should be_truthy }
        it {
          m = subject.class.new
          m.add_role("moderator", Forum.first)
          m.has_cached_role?("moderator".send(param_method), :any).should be_truthy
        }
      end

      it "should not get an instance scoped role when asking for a global" do
        subject.has_role?("moderator".send(param_method)).should be_falsey

        subject.has_cached_role?("moderator".send(param_method)).should be_falsey
      end

      it "should not get an instance scoped role when asking for a class scoped" do 
        subject.has_role?("moderator".send(param_method), Forum).should be_falsey

        subject.has_cached_role?("moderator".send(param_method), Forum).should be_falsey
      end

      it "should not get a global role" do
        role_class.create(:name => "admin")
        subject.has_role?("admin".send(param_method)).should be_falsey

        subject.has_cached_role?("admin".send(param_method)).should be_falsey
      end

      context "with another instance scoped role" do
        context "on the same resource but with a different role name" do
          before(:all) { role_class.create(:name => "member", :resource => Forum.first) }

          it { subject.has_role?("member".send(param_method), Forum.first).should be_falsey }
          it { subject.has_role?("member".send(param_method), :any).should be_falsey }

          it { subject.has_cached_role?("member".send(param_method), Forum.first).should be_falsey }
          it { subject.has_cached_role?("member".send(param_method), :any).should be_falsey }
        end

        context "on another resource of the same type but with the same role name" do
          before(:all) { role_class.create(:name => "moderator", :resource => Forum.last) }

          it { subject.has_role?("moderator".send(param_method), Forum.last).should be_falsey }
          it { subject.has_role?("moderator".send(param_method), :any).should be_truthy }

          it { subject.has_cached_role?("moderator".send(param_method), Forum.last).should be_falsey }
          it { subject.has_cached_role?("moderator".send(param_method), :any).should be_truthy }
        end

        context "on another resource of different type but with the same role name" do
          before(:all) { role_class.create(:name => "moderator", :resource => Group.last) }

          it { subject.has_role?("moderator".send(param_method), Group.last).should be_falsey }
          it { subject.has_role?("moderator".send(param_method), :any).should be_truthy }

          it { subject.has_cached_role?("moderator".send(param_method), Group.last).should be_falsey }
          it { subject.has_cached_role?("moderator".send(param_method), :any).should be_truthy }
        end

        context "on another resource of the same type and with another role name" do
          before(:all) { role_class.create(:name => "member", :resource => Forum.last) }

          it { subject.has_role?("member".send(param_method), Forum.last).should be_falsey }
          it { subject.has_role?("member".send(param_method), :any).should be_falsey }

          it { subject.has_cached_role?("member".send(param_method), Forum.last).should be_falsey }
          it { subject.has_cached_role?("member".send(param_method), :any).should be_falsey }
        end

        context "on another resource of different type and with another role name" do
          before(:all) { role_class.create(:name => "member", :resource => Group.first) }

          it { subject.has_role?("member".send(param_method), Group.first).should be_falsey }
          it { subject.has_role?("member".send(param_method), :any).should be_falsey }

          it { subject.has_cached_role?("member".send(param_method), Group.first).should be_falsey }
          it { subject.has_cached_role?("member".send(param_method), :any).should be_falsey }
        end
      end
    end
  end
end
