FactoryBot.define do
  factory :comment do
    message { nil }
    user { nil }
    content { "MyText" }
    deleted_at { "2026-01-27 16:57:44" }
  end
end
