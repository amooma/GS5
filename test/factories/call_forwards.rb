# Read about factories at http://github.com/thoughtbot/factory_girl

Factory.define :call_forward do |f|
  f.association :phone_number
  #OPTIMIZE Make sure that the phone_number's phone_numberable
  # isn't a phone_book_entry but a sip_account.
  #f.sequence( :call_forward_case_id ) { |n| CallForwardCase.where(:value => "always").first.id }
  #f.association :call_forward_case
  f.sequence( :call_forward_case_id  ) { |n| 1 }
  f.sequence( :destination  ) { |n| "20#{n}" }
  f.sequence( :to_voicemail ) { |n| false }
  f.sequence( :timeout      ) { |n| nil }
  f.sequence( :source       ) { |n| nil }
  f.sequence( :depth        ) { |n| 5 }
  f.sequence( :active       ) { |n| false }
end
