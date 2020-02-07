FactoryBot.define do
  factory :backup_data do
    association :instance_user, factory: :user
    after(:build) do |backup_data|
      backup_data.instance = backup_data.instance_user.identities.first || create(:identity, user: backup_data.instance_user)
      backup_data.json_data = backup_data.instance.attributes
    end
  end
end
