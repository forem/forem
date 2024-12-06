require "spec_helper"

describe "Resourcify and rolify on the same model" do
  
  before(:all) do
    reset_defaults
    Role.delete_all
    HumanResource.delete_all
  end
  
  let!(:user) do
    user = HumanResource.new login: 'Samer' 
    user.save
    user
  end
  
  it "should add the role to the user" do
    expect { user.add_role :admin }.to change { user.roles.count }.by(1)
  end
      
  it "should create a role to the roles collection" do
    expect { user.add_role :moderator }.to change { Role.count }.by(1)
  end
end