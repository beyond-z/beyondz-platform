# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :application do
    active false
    associated_campaign "MyString"
  end
end
