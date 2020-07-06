FactoryGirl.define do
  factory :daddy, :class => Some do |b|
    b.name 'Daddy'
  end

  factory :mommy, :class => Some do |b|
    b.name 'Mommy'
  end
end
