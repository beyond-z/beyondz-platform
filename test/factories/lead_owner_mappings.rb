# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :lead_owner_mapping do
    lead_owner "MyString"
    applicant_type "MyString"
    state "MyString"
    interested_joining "MyString"
  end
end
