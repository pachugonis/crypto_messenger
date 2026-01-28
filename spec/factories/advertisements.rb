FactoryBot.define do
  factory :advertisement do
    title { "MyString" }
    content { "MyText" }
    image_url { "MyString" }
    link { "MyString" }
    position { 1 }
    active { false }
  end
end
