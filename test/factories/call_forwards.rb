# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :call_forward do
    association :phone_number
    #OPTIMIZE Make sure that the phone_number's phone_numberable
    # isn't a phone_book_entry but a sip_account.
    #f.sequence( :call_forward_case_id ) { |n| CallForwardCase.where(:value => "always").first.id }
    #f.association :call_forward_case
    sequence( :call_forward_case_id  ) { |n| 1 }
    sequence( :destination  ) { |n| "20#{n}" }
    sequence( :to_voicemail ) { |n| false }
    sequence( :timeout      ) { |n| nil }
    sequence( :source       ) { |n| nil }
    sequence( :depth        ) { |n| 5 }
    sequence( :active       ) { |n| false }
  end
end
