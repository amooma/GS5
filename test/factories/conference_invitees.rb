# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :conference_invitee do
    phone_number { FactoryGirl.build(:phone_number) }
    association :conference
    speaker true
    moderator false
  end
end