FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user#{n}" }
    password { "password123" }
    role { :user }

    trait :admin do
      role { :admin }
    end

    trait :locked do
      locked_at { Time.current }
    end
  end
end
