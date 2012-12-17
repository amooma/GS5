# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :gui_function_membership do
    gui_function_id 1
    user_group_id 1
    activated false
    output "MyString"
  end
end
