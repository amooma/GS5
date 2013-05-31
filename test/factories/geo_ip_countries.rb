# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :geo_ip_country do
    from "MyString"
    to "MyString"
    n_from 1
    n_to 1
    country_id 1
    country_code "MyString"
    country_name "MyString"
  end
end
