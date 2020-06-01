FactoryBot.define do
  sequence(:old_path) { |n| "/old-path-#{n}" }
  sequence(:new_path) { |n| "/new-path-#{n}" }

  factory :path_redirect do
    old_path { generate :old_path }
    new_path { generate :new_path }
  end
end
