# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :salesforce_cach, :class => 'SalesforceCache' do
    key "MyString"
    value "MyText"
  end
end
