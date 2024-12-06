shared_examples_for "#has_all_roles?_examples" do |param_name, param_method|
  context "using #{param_name} as parameter" do
    context "with a global role", :scope => :global do  
      context "on global roles only request" do
        it { subject.has_all_roles?("staff".send(param_method)).should be_truthy }
        it { subject.has_all_roles?("admin".send(param_method), "staff".send(param_method)).should be_truthy }
        it { subject.has_all_roles?("admin".send(param_method), "dummy".send(param_method)).should be_falsey }
        it { subject.has_all_roles?("dummy".send(param_method), "dumber".send(param_method)).should be_falsey }
      end
      
      context "on mixed scoped roles" do
        it { subject.has_all_roles?({ :name => "admin".send(param_method), :resource => Forum }, { :name => "admin".send(param_method), :resource => Group }).should be_truthy }
        it { subject.has_all_roles?({ :name => "admin".send(param_method), :resource => :any }, { :name => "admin".send(param_method), :resource => Group }).should be_truthy }
        it { subject.has_all_roles?({ :name => "admin".send(param_method), :resource => Forum }, { :name => "staff".send(param_method), :resource => Group.last }).should be_truthy }
        it { subject.has_all_roles?({ :name => "admin".send(param_method), :resource => Forum.first }, { :name => "admin".send(param_method), :resource => Forum.last }).should be_truthy }
        it { subject.has_all_roles?({ :name => "admin".send(param_method), :resource => Forum.first }, { :name => "dummy".send(param_method), :resource => Forum.last }).should be_falsey }
        it { subject.has_all_roles?({ :name => "admin".send(param_method), :resource => Forum.first }, { :name => "dummy".send(param_method), :resource => :any }).should be_falsey}
      end
    end
    
    context "with a class scoped role", :scope => :class do        
      context "on class scoped roles only" do
        it { subject.has_all_roles?({ :name => "player".send(param_method), :resource => Forum }).should be_truthy }
        it { subject.has_all_roles?({ :name => "manager".send(param_method), :resource => Forum }, { :name => "player".send(param_method), :resource => Forum }).should be_truthy }
        it { subject.has_all_roles?({ :name => "manager".send(param_method), :resource => :any }, { :name => "player".send(param_method), :resource => Forum }).should be_truthy }
        it { subject.has_all_roles?({ :name => "manager".send(param_method), :resource => :any }, { :name => "player".send(param_method), :resource => :any }).should be_truthy }
        it { subject.has_all_roles?({ :name => "manager".send(param_method), :resource => Forum }, { :name => "dummy".send(param_method), :resource => Forum }).should be_falsey }
        it { subject.has_all_roles?({ :name => "manager".send(param_method), :resource => Forum }, { :name => "dummy".send(param_method), :resource => :any }).should be_falsey }
        it { subject.has_all_roles?({ :name => "dummy".send(param_method), :resource => Forum }, { :name => "dumber".send(param_method), :resource => Group }).should be_falsey }
      end
      
      context "on mixed scoped roles" do
        it { subject.has_all_roles?({ :name => "manager".send(param_method), :resource => Forum.first }, { :name => "manager".send(param_method), :resource => Forum.last }).should be_truthy }
        it { subject.has_all_roles?({ :name => "manager".send(param_method), :resource => Group }, { :name => "moderator".send(param_method), :resource => Forum.first }).should be_falsey }
        it { subject.has_all_roles?({ :name => "manager".send(param_method), :resource => Forum.first }, { :name => "moderator".send(param_method), :resource => Forum }).should be_falsey }
        it { subject.has_all_roles?({ :name => "manager".send(param_method), :resource => Forum.last }, { :name => "warrior".send(param_method), :resource => Forum.last }).should be_truthy }
      end
    end
    
    context "with a instance scoped role", :scope => :instance do
      context "on instance scoped roles only" do
        it { subject.has_all_roles?({ :name => "moderator".send(param_method), :resource => :any }, { :name => "anonymous".send(param_method), :resource => Forum.last }).should be_truthy }
        it { subject.has_all_roles?({ :name => "moderator".send(param_method), :resource => :any }, { :name => "anonymous".send(param_method), :resource => :any }).should be_truthy }
        it { subject.has_all_roles?({ :name => "moderator".send(param_method), :resource => :any }, { :name => "anonymous".send(param_method), :resource => Forum }).should be_falsey }
        it { subject.has_all_roles?({ :name => "moderator".send(param_method), :resource => Forum.first }, { :name => "anonymous".send(param_method), :resource => Forum.last }).should be_truthy }
        it { subject.has_all_roles?({ :name => "moderator".send(param_method), :resource => Forum.first }, { :name => "moderator".send(param_method), :resource => Forum.last }).should be_falsey }
        it { subject.has_all_roles?({ :name => "moderator".send(param_method), :resource => Forum.first }, { :name => "dummy".send(param_method), :resource => Forum.last }).should be_falsey }
        it { subject.has_all_roles?({ :name => "dummy".send(param_method), :resource => Forum.first }, { :name => "dumber".send(param_method), :resource => Forum.last }).should be_falsey }
      end
      
      context "on mixed scoped roles" do
        it { subject.has_all_roles?({ :name => "visitor".send(param_method), :resource => Forum.last }).should be_truthy }
        it { subject.has_all_roles?("soldier".send(param_method), { :name => "moderator".send(param_method), :resource => Forum.first }, { :name => "visitor".send(param_method), :resource => Forum }).should be(true) }
        it { subject.has_all_roles?("soldier".send(param_method), { :name => "moderator".send(param_method), :resource => Forum.last }, { :name => "visitor".send(param_method), :resource => Forum }).should be(false) }
        it { subject.has_all_roles?("soldier".send(param_method), { :name => "moderator".send(param_method), :resource => :any }, { :name => "visitor".send(param_method), :resource => Forum }).should be(true) }
        it { subject.has_all_roles?("soldier".send(param_method), { :name => "moderator".send(param_method), :resource => :any }, { :name => "visitor".send(param_method), :resource => :any }).should be(true) }
        it { subject.has_all_roles?("soldier".send(param_method), { :name => "moderator".send(param_method), :resource => Forum.first }, { :name => "visitor".send(param_method), :resource => Group }).should be(false) }
        it { subject.has_all_roles?("soldier".send(param_method), { :name => "moderator".send(param_method), :resource => Forum.first }, { :name => "visitor".send(param_method), :resource => Group.first }).should be(false) }
        it { subject.has_all_roles?({ :name => "soldier".send(param_method), :resource => Forum }, { :name => "moderator".send(param_method), :resource => Forum.first }, { :name => "visitor".send(param_method), :resource => Forum }).should be(true) }
        it { subject.has_all_roles?({ :name => "soldier".send(param_method), :resource => Forum.first }, { :name => "moderator".send(param_method), :resource => Forum.first }, { :name => "visitor".send(param_method), :resource => Forum }).should be(true) }
        it { subject.has_all_roles?("soldier".send(param_method), { :name => "moderator".send(param_method), :resource => Forum.first }, { :name => "visitor".send(param_method), :resource => Forum.first }).should be(true) }
        it { subject.has_all_roles?("dummy".send(param_method), { :name => "dumber".send(param_method), :resource => Forum.last }, { :name => "dumberer".send(param_method), :resource => Forum }).should be(false) }
        it { subject.has_all_roles?("soldier".send(param_method), "dummy".send(param_method), { :name => "dumber".send(param_method), :resource => Forum.last }, { :name => "dumberer".send(param_method), :resource => Forum }).should be(false) }
        it { subject.has_all_roles?({ :name => "manager".send(param_method), :resource => Forum.last }, "dummy".send(param_method), { :name => "dumber".send(param_method), :resource => Forum.last }, { :name => "dumberer".send(param_method), :resource => Forum }).should be(false) }
        it { subject.has_all_roles?("soldier".send(param_method), { :name => "dumber".send(param_method), :resource => Forum.last }, { :name => "manager".send(param_method), :resource => Forum.last }).should be(false) }
        it { subject.has_all_roles?({ :name => "soldier".send(param_method), :resource => Forum.first }, { :name => "moderator".send(param_method), :resource => Forum.first }, { :name => "visitor".send(param_method), :resource => Forum.last }).should be(true) }
        it { subject.has_all_roles?({ :name => "soldier".send(param_method), :resource => Forum.first }, { :name => "moderator".send(param_method), :resource => :any }, { :name => "visitor".send(param_method), :resource => Forum.last }).should be(true) }
      end
    end
  end
end