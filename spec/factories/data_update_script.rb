FactoryBot.define do
  factory :data_update_script do
    file_name { |n| "20200214151804_data_update_test_script#{n}" }
  end
end
