FactoryBot.define do
  factory :message do
    association :room
    association :user
    content { "Test message content" }
    message_type { :text }

    trait :system do
      message_type { :system }
    end

    trait :deleted do
      content { "" }
      deleted_at { Time.current }
    end
  end
end
