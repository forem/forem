FactoryGirl.define do
  factory :jon, class: User do |u|
    u.name 'Jon'
  end

  factory :sam, class: User do |u|
    u.name 'Sam'
   end

  factory :bob, class: User do |u|
    u.name 'Bob'
  end
end
