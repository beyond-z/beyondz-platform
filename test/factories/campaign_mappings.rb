# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :campaign_mapping do
    campaign_id "MyString"
    applicant_type "MyString"
    university_name "MyString"
    bz_region "MyString"
  end
end
