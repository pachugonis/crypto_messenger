FactoryBot.define do
  factory :attachment do
    attachable { nil }
    user { nil }
    access_token { "MyString" }
    access_token_expires_at { "2026-01-20 20:13:08" }
  end
end
