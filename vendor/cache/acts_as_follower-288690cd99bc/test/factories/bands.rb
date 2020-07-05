FactoryGirl.define do
  factory :oasis, class: Band do |b|
    b.name 'Oasis'
  end

  factory :metallica, class: Band do |b|
    b.name 'Metallica'
  end
  
  factory :green_day, :class => Band::Punk do |b|
    b.name 'Green Day'
  end

  factory :blink_182, :class => Band::Punk::PopPunk do |b|
    b.name 'Blink 182'
  end
end
