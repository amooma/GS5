require 'test_helper'

class PhoneBookEntryTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert Factory.build(:phone_book_entry).valid?
  end

  # TODO Fix this test.
  
  # test "only user can read entries in private phone books" do
  #   user = Factory.create(:user)
  #   phone_book = Factory.create(:phone_book, :phone_bookable_type => 'User', :phone_bookable_id => user.id)
  #   phone_book_entry = Factory.create(:phone_book_entry, :phone_book_id => phone_book.id)

  #   evil_user = Factory.create(:user)

  #   user_ability = Ability.new( user )
  #   evil_user_ability = Ability.new( evil_user )

  #   [ :show, :index ].each { |action|
  #     assert user_ability.can?    action, phone_book_entry
  #     assert evil_user_ability.cannot? action, phone_book_entry
  #   }
  # end
  
  def test_that_the_initial_state_should_be_active
    @phone_book_entry = Factory.create(:phone_book_entry)
    assert_equal 'active', @phone_book_entry.state
    assert @phone_book_entry.active?
  end
  
  test "a destroyed phone_book will destroy all phone_book_entries" do
    phone_book = Factory.create(:phone_book)
    10.times { Factory.create(:phone_book_entry, :phone_book_id => phone_book.id) }
    
    phone_book2 = Factory.create(:phone_book)
    5.times { Factory.create(:phone_book_entry, :phone_book_id => phone_book2.id) }
    
    assert_equal 15, PhoneBookEntry.all.count
    
    phone_book.destroy
    
    assert_equal 5, PhoneBookEntry.all.count
  end

  test "that the value_of_to_s field is filled" do
    phone_book_entry = Factory.create(:phone_book_entry)
    assert_equal phone_book_entry.value_of_to_s, phone_book_entry.to_s
  end

end
