require 'test_helper'

class UserGroupMembershipTest < ActiveSupport::TestCase
  def test_should_have_a_valid_factory
    assert FactoryGirl.build(:user_group_membership).valid?
  end
  def test_should_have_unique_members_in_each_group
    group1 = FactoryGirl.create(:user_group)
    group2 = FactoryGirl.create(:user_group)
    user1 = FactoryGirl.create(:user)
    user2 = FactoryGirl.create(:user)
    member = FactoryGirl.create(
                            :user_group_membership,
                            :user_id => user1.id,
                            :user_group_id => group1.id
                            )
    assert !FactoryGirl.build(
                          :user_group_membership,
                          :user_id => user1.id,
                          :user_group_id => group1.id
                            ).valid?
    assert FactoryGirl.build(
                          :user_group_membership,
                          :user_id => user1.id,
                          :user_group_id => group2.id
                            ).valid?
    assert FactoryGirl.build(
                          :user_group_membership,
                          :user_id => user2.id,
                          :user_group_id => group1.id
                            ).valid?
  end
  
  def test_that_the_initial_state_should_be_active
    @user_group_membership = FactoryGirl.create(:user_group_membership)
    assert_equal 'active', @user_group_membership.state
    assert @user_group_membership.active?
  end
end
