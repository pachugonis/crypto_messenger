FactoryBot.define do
  factory :room_participant do
    association :user
    association :room
    role { :member }
    muted { false }

    trait :owner do
      role { :owner }
    end

    trait :admin do
      role { :admin }
    end
  end
end
