# Users
[ User, Customer, Admin::Moderator, StrictUser ].each do |user|
  user.destroy_all

  user.create(:login => "admin")
  user.create(:login => "moderator")
  user.create(:login => "god")
  user.create(:login => "zombie")
end

# Roles
[ Role, Privilege, Admin::Right ].each do |role|
  role.destroy_all
end

# Resources
Forum.create(:name => "forum 1")
Forum.create(:name => "forum 2")
Forum.create(:name => "forum 3")

Group.create(:name => "group 1")
Group.create(:name => "group 2")

Team.create(:team_code => "1", :name => "PSG")
Team.create(:team_code => "2", :name => "MU")

Organization.create
Company.create
