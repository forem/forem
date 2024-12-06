shared_examples_for "#only_has_role?_examples" do |param_name, param_method|
  context "using #{param_name} as parameter" do
    context "with a global role", :scope => :global do
      subject do 
        user = User.create(:login => "global_user")
        user.add_role "global_role".send(param_method)
        user
      end
      
      it { subject.only_has_role?("global_role".send(param_method)).should be_truthy }

      context "on resource request" do
        it { subject.only_has_role?("global_role".send(param_method), Forum.first).should be_truthy }
        it { subject.only_has_role?("global_role".send(param_method), Forum).should be_truthy }
        it { subject.only_has_role?("global_role".send(param_method), :any).should be_truthy }
      end

      context "with another global role" do
        before(:all) { role_class.create(:name => "another_global_role") }

        it { subject.only_has_role?("another_global_role".send(param_method)).should be_falsey }
        it { subject.only_has_role?("another_global_role".send(param_method), :any).should be_falsey }
      end

      it "should not get an instance scoped role" do
        subject.only_has_role?("moderator".send(param_method), Group.first).should be_falsey
      end

      it "should not get a class scoped role" do
        subject.only_has_role?("manager".send(param_method), Forum).should be_falsey
      end

      context "using inexisting role" do
        it { subject.only_has_role?("dummy".send(param_method)).should be_falsey }
        it { subject.only_has_role?("dumber".send(param_method), Forum.first).should be_falsey }
      end
      
      context "with multiple roles" do
        before { subject.add_role "multiple_global_roles".send(param_method) }
        
        it { subject.only_has_role?("global_role".send(param_method)).should be_falsey }
      end
    end

    context "with a class scoped role", :scope => :class do
      subject do 
        user = User.create(:login => "class_user")
        user.add_role "class_role".send(param_method), Forum
        user
      end
      
      context "on class scoped role request" do
        it { subject.only_has_role?("class_role".send(param_method), Forum).should be_truthy }
        it { subject.only_has_role?("class_role".send(param_method), Forum.first).should be_truthy }
        it { subject.only_has_role?("class_role".send(param_method), :any).should be_truthy }
      end

      it "should not get a scoped role when asking for a global" do
        subject.only_has_role?("class_role".send(param_method)).should be_falsey
      end

      it "should not get a global role" do
        role_class.create(:name => "global_role")
        subject.only_has_role?("global_role".send(param_method)).should be_falsey
      end

      context "with another class scoped role" do
        context "on the same resource but with a different name" do
          before(:all) { role_class.create(:name => "another_class_role", :resource_type => "Forum") }

          it { subject.only_has_role?("another_class_role".send(param_method), Forum).should be_falsey }
          it { subject.only_has_role?("another_class_role".send(param_method), :any).should be_falsey }
        end

        context "on another resource with the same name" do
          before(:all) { role_class.create(:name => "class_role", :resource_type => "Group") }

          it { subject.only_has_role?("class_role".send(param_method), Group).should be_falsey }
          it { subject.only_has_role?("class_role".send(param_method), :any).should be_truthy }
        end

        context "on another resource with another name" do
          before(:all) { role_class.create(:name => "another_class_role", :resource_type => "Group") }

          it { subject.only_has_role?("another_class_role".send(param_method), Group).should be_falsey }
          it { subject.only_has_role?("another_class_role".send(param_method), :any).should be_falsey }
        end
      end

      context "using inexisting role" do
        it { subject.only_has_role?("dummy".send(param_method), Forum).should be_falsey }
        it { subject.only_has_role?("dumber".send(param_method)).should be_falsey }
      end
      
      context "with multiple roles" do
        before { subject.add_role "multiple_class_roles".send(param_method) }
        
        it { subject.only_has_role?("class_role".send(param_method), Forum).should be_falsey }
        it { subject.only_has_role?("class_role".send(param_method), Forum.first).should be_falsey }
        it { subject.only_has_role?("class_role".send(param_method), :any).should be_falsey }  
      end
    end

    context "with a instance scoped role", :scope => :instance do
      subject do 
        user = User.create(:login => "instance_user")
        user.add_role "instance_role".send(param_method), Forum.first
        user
      end
      
      context "on instance scoped role request" do
        it { subject.only_has_role?("instance_role".send(param_method), Forum.first).should be_truthy }
        it { subject.only_has_role?("instance_role".send(param_method), :any).should be_truthy }
      end

      it "should not get an instance scoped role when asking for a global" do
        subject.only_has_role?("instance_role".send(param_method)).should be_falsey
      end

      it "should not get an instance scoped role when asking for a class scoped" do 
        subject.only_has_role?("instance_role".send(param_method), Forum).should be_falsey
      end

      it "should not get a global role" do
        role_class.create(:name => "global_role")
        subject.only_has_role?("global_role".send(param_method)).should be_falsey
      end

      context "with another instance scoped role" do
        context "on the same resource but with a different role name" do
          before(:all) { role_class.create(:name => "another_instance_role", :resource => Forum.first) }

          it { subject.only_has_role?("another_instance_role".send(param_method), Forum.first).should be_falsey }
          it { subject.only_has_role?("another_instance_role".send(param_method), :any).should be_falsey }
        end

        context "on another resource of the same type but with the same role name" do
          before(:all) { role_class.create(:name => "moderator", :resource => Forum.last) }

          it { subject.only_has_role?("instance_role".send(param_method), Forum.last).should be_falsey }
          it { subject.only_has_role?("instance_role".send(param_method), :any).should be_truthy }
        end

        context "on another resource of different type but with the same role name" do
          before(:all) { role_class.create(:name => "moderator", :resource => Group.last) }

          it { subject.only_has_role?("instance_role".send(param_method), Group.last).should be_falsey }
          it { subject.only_has_role?("instance_role".send(param_method), :any).should be_truthy }
        end

        context "on another resource of the same type and with another role name" do
          before(:all) { role_class.create(:name => "another_instance_role", :resource => Forum.last) }

          it { subject.only_has_role?("another_instance_role".send(param_method), Forum.last).should be_falsey }
          it { subject.only_has_role?("another_instance_role".send(param_method), :any).should be_falsey }
        end

        context "on another resource of different type and with another role name" do
          before(:all) { role_class.create(:name => "another_instance_role", :resource => Group.first) }

          it { subject.only_has_role?("another_instance_role".send(param_method), Group.first).should be_falsey }
          it { subject.only_has_role?("another_instance_role".send(param_method), :any).should be_falsey }
        end
      end
    
      context "with multiple roles" do
        before { subject.add_role "multiple_instance_roles".send(param_method), Forum.first }
        
        it { subject.only_has_role?("instance_role".send(param_method), Forum.first).should be_falsey }
        it { subject.only_has_role?("instance_role".send(param_method), :any).should be_falsey }
      end
    end
  end
end