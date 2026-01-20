FactoryBot.define do
  factory :folder do
    association :user
    sequence(:name) { |n| "Folder #{n}" }
    parent_folder { nil }
  end
end
