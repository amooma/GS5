# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :conference_invitee do |f|
  f.phone_number { Factory.build(:phone_number) }
  f.association :conference
  f.speaker true
  f.moderator false
end