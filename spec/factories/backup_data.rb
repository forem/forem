FactoryBot.define do
  factory :backup_data do
    before(:create) do |backup_data|
      backup_data.instance_user ||= create(:user)
      backup_data.instance = backup_data.instance_user.identities.first || create(:identity, user: backup_data.instance_user)
      backup_data.json_data = backup_data.instance.attributes
    end
    # association :instance_user, factory: :user
    # association :instance, factory: :identity, user: user
  end
end
