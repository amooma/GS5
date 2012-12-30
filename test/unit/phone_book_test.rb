require 'test_helper'

class PhoneBookTest < ActiveSupport::TestCase
  def test_should_have_a_valid_factory
    assert FactoryGirl.build(:phone_book).valid?
  end

  def test_should_have_unique_name_depending_on_type
      user1 = FactoryGirl.create(:user)
      user2 = FactoryGirl.create(:user)
      tenant = FactoryGirl.create(:tenant)
      
      phonebook = FactoryGirl.create(:phone_book, :phone_bookable => user1)
      assert !user1.phone_books.build(:name => phonebook.name).valid?
      assert user2.phone_books.build(:name => phonebook.name).valid?
      assert tenant.phone_books.build(:name => phonebook.name).valid?
  end
  
  # TODO Create a real system for the phone_book tests and than test again.


  # test "User gets a private phone book with rw rights" do
  #   user = FactoryGirl.create(:user)
  #   assert_equal 1, user.phone_books.count

  #   phone_book = user.phone_books.first
    
  #   user_ability = Ability.new( user )

  #   [ :show, :destroy, :edit ].each { |action|
  #     assert user_ability.can?( action, phone_book ), "should be able to #{action}"
  #   }

  #   # Lets test some stuff about the phone_book_entries
  #   assert_equal 0, phone_book.phone_book_entries.count
        
  #   entry1 = FactoryGirl.create(:phone_book_entry, :phone_book_id => phone_book.id)
  #   entry2 = FactoryGirl.create(:phone_book_entry, :phone_book_id => phone_book.id)
  #   entry3 = FactoryGirl.create(:phone_book_entry, :phone_book_id => phone_book.id)
  #   assert_equal 3, phone_book.phone_book_entries.count

  #   assert_equal 1, PhoneBookEntry.where(:id => entry1.id).count
  #   assert_equal 1, PhoneBookEntry.where(:id => entry2.id).count
  #   assert_equal 1, PhoneBookEntry.where(:id => entry3.id).count
  #   user.phone_books.first.destroy
  #   assert_equal 0, user.phone_books.count
  #   assert_equal 0, PhoneBookEntry.where(:id => entry1.id).count
  #   assert_equal 0, PhoneBookEntry.where(:id => entry2.id).count
  #   assert_equal 0, PhoneBookEntry.where(:id => entry3.id).count
  # end 

  test "Tenant gets automatically one phone book and can destroy it" do
    tenant = FactoryGirl.create(:tenant)
    assert_equal 1, tenant.phone_books.count
    tenant.phone_books.first.destroy
    assert_equal 0, tenant.phone_books.count
  end
  
  # test "only tenant members can read a tenant phone book" do
  #   tenant = FactoryGirl.create(:tenant)
  #   user = FactoryGirl.create(:user)
  #   tenant.users << user
  #   tenant.save
  #   user.current_tenant = tenant
  #   user.save
  #   phone_book = FactoryGirl.create(:phone_book, :phone_bookable_type => 'Tenant', :phone_bookable_id => tenant.id)

  #   evil_user = FactoryGirl.create(:user)

  #   user_ability = Ability.new( user )
  #   evil_user_ability = Ability.new( evil_user )

  #   [ :show ].each { |action|
  #     assert user_ability.can?( action, phone_book ), "should be able to #{action}"
  #     assert evil_user_ability.cannot?( action, phone_book ), "should not be able to #{action}"
  #   }
  # end



  # test "tenant's phone book can not be edited by tenant members" do
  #   tenant = FactoryGirl.create(:tenant)
  #   user = FactoryGirl.create(:user)
  #   tenant.users << user
  #   phone_book = FactoryGirl.create(:phone_book, :phone_bookable_type => 'Tenant', :phone_bookable_id => tenant.id)

  #   evil_user = FactoryGirl.create(:user)

  #   user_ability = Ability.new( user )
  #   evil_user_ability = Ability.new( evil_user )

  #   [ :edit, :destroy ].each { |action|
  #     assert user_ability.cannot?( action, phone_book ), "should not be able to #{action}"
  #     assert evil_user_ability.cannot?( action, phone_book ), "should not be able to #{action}"
  #   }
  # end
  
  # test "only user can manage his private phone book after creating it" do
  #   user = FactoryGirl.create(:user)
  #   phone_book = FactoryGirl.create(:phone_book, :phone_bookable_type => 'User', :phone_bookable_id => user.id)

  #   evil_user = FactoryGirl.create(:user)

  #   user_ability = Ability.new( user )
  #   evil_user_ability = Ability.new( evil_user )

  #   [ :show, :destroy, :edit ].each { |action|
  #     assert user_ability.can?( action, phone_book ), "should be able to #{action}"
  #     assert evil_user_ability.cannot?( action, phone_book ), "should not be able to #{action}"
  #   }
  # end

  def test_that_the_initial_state_should_be_active
    @phone_book = FactoryGirl.create(:phone_book)
    assert_equal 'active', @phone_book.state
    assert @phone_book.active?
  end
  
end
