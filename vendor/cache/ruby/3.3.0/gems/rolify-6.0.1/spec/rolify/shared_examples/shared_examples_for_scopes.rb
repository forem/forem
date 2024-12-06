require "rolify/shared_contexts"

shared_examples_for "Role.scopes" do
  before do
    role_class.destroy_all
  end
  
  subject { user_class.first }
  
  describe ".global" do 
    let!(:admin_role) { subject.add_role :admin }
    let!(:staff_role) { subject.add_role :staff }
     
    it { subject.roles.global.should == [ admin_role, staff_role ] }
  end
  
  describe ".class_scoped" do
    let!(:manager_role) { subject.add_role :manager, Group }
    let!(:moderator_role) { subject.add_role :moderator, Forum }
    
    it { subject.roles.class_scoped.should =~ [ manager_role, moderator_role ] }
    it { subject.roles.class_scoped(Group).should =~ [ manager_role ] }
    it { subject.roles.class_scoped(Forum).should =~ [ moderator_role ] }
  end
  
  describe ".instance_scoped" do
    let!(:visitor_role) { subject.add_role :visitor, Forum.first }
    let!(:zombie_role) { subject.add_role :visitor, Forum.last }
    let!(:anonymous_role) { subject.add_role :anonymous, Group.last }
    
    it { subject.roles.instance_scoped.to_a.entries.should =~ [ visitor_role, zombie_role, anonymous_role ] }
    it { subject.roles.instance_scoped(Forum).should =~ [ visitor_role, zombie_role ] }
    it { subject.roles.instance_scoped(Forum.first).should =~ [ visitor_role ] }
    it { subject.roles.instance_scoped(Forum.last).should =~ [ zombie_role ] }
    it { subject.roles.instance_scoped(Group.last).should =~ [ anonymous_role ] }
    it { subject.roles.instance_scoped(Group.first).should be_empty }
  end
end