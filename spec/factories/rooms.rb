FactoryBot.define do
  factory :room do
    sequence(:name) { |n| "Room #{n}" }
    room_type { :group }
    description { "Test room description" }
    visibility { :private_room }

    trait :personal_chat do
      room_type { :personal_chat }
      sequence(:name) { |n| "Chat #{n}" }
    end

    trait :group do
      room_type { :group }
    end

    trait :channel do
      room_type { :channel }
    end

    trait :public do
      visibility { :public_room }
    end
  end
end
