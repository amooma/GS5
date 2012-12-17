require 'test_helper'

class UserTest < ActiveSupport::TestCase
  
  def test_should_have_a_valid_factory
    assert Factory.build(:user).valid?
  end
  
  def test_should_have_a_unique_email_address
    user = Factory.create(:user)
    assert !Factory.build(:user, :email => user.email).valid?
    assert Factory.build(:user, :email => "different_#{user.email}").valid?
  end
  
  def test_can_not_move_to_a_current_tenant_without_a_membership_relation
    super_tenant = Factory.create(:tenant)
    good_tenant = Factory.create(:tenant)
    evil_tenant = Factory.create(:tenant)
    
    user = Factory.create(:user)
    super_tenant.tenant_memberships.create(:user_id => user.id)
    good_tenant.tenant_memberships.create(:user_id => user.id)
    
    assert user.update_attributes(:current_tenant_id => super_tenant.id)
    assert !user.update_attributes(:current_tenant_id => evil_tenant.id)
    assert user.update_attributes(:current_tenant_id => good_tenant.id)
  end
  
  test "should be possible to modify the user without changing the PIN" do
    user = Factory.create(:user)
    pin_salt = user.pin_salt
    pin_hash = user.pin_hash
    user.middle_name = "#{user.middle_name} Foo"
    assert user.save, "Should be possible to save the user."
    user = User.where(:id => user.id).first
    assert user
    assert_equal pin_salt, user.pin_salt, "PIN salt should not change."
    assert_equal pin_hash, user.pin_hash, "PIN hash should not change."
  end
  
  test "should be possible to change the PIN" do
    user = Factory.create(:user)
    pin_salt = user.pin_salt
    pin_hash = user.pin_hash
    new_pin = '453267'
    user.new_pin              = new_pin
    user.new_pin_confirmation = new_pin
    assert user.save, "Should be possible to save the user."
    user = User.where(:id => user.id).first
    assert_not_equal "#{pin_salt}#{pin_hash}", "#{user.pin_salt}#{user.pin_hash}",
      "PIN salt/hash should have changed."
  end
  
  test "should not be possible to change the PIN if the confirmation does not match" do
    user = Factory.create(:user)
    pin_salt = user.pin_salt
    pin_hash = user.pin_hash
    user.new_pin              = '123001'
    user.new_pin_confirmation = '123002'
    assert ! user.save, "Should not be possible to save the user."
    assert ! user.valid?, "Should not be valid."
    assert user.errors && user.errors.messages
    assert (
      (user.errors.messages[:new_pin] && user.errors.messages[:new_pin].length > 0) ||
      (user.errors.messages[:new_pin_confirmation] && user.errors.messages[:new_pin_confirmation].length > 0)
    ), "There should be an error message because new_pin != new_pin_confirmation."
  end
  
  test "PIN must be numeric" do
    user = Factory.create(:user)
    new_pin = 'xxxx'
    user.new_pin              = new_pin
    user.new_pin_confirmation = new_pin
    assert ! user.save, "Should not be possible to save the user."
    assert ! user.valid?, "Should not be valid."
    assert (
      (user.errors.messages[:new_pin] && user.errors.messages[:new_pin].length > 0) ||
      (user.errors.messages[:new_pin_confirmation] && user.errors.messages[:new_pin_confirmation].length > 0)
    ), "There should be an error message because PIN isn't numeric."
  end
  
end
