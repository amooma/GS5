require 'test_helper'

class UserGroupTest < ActiveSupport::TestCase
  def test_should_have_a_valid_factory
    assert FactoryGirl.build(:user_group).valid?
  end
  
  def test_should_have_unique_name_on_same_tenant
    tenant1 = FactoryGirl.create(:tenant)
    tenant2 = FactoryGirl.create(:tenant)
    group = FactoryGirl.create(:user_group, :tenant_id => tenant1.id)
    assert !FactoryGirl.build(:user_group, :name => group.name, :tenant_id => tenant1.id).valid?
    assert FactoryGirl.build(:user_group, :name => group.name, :tenant_id => tenant2.id).valid?
    assert FactoryGirl.build(:user_group, :name => "different_#{group.name}", :tenant_id => tenant1.id).valid?
  end
  
  test "user_group_membership only available for tenant_memberships" do
    good_tenant = FactoryGirl.create(:tenant)
    evil_tenant = FactoryGirl.create(:tenant)

    user = FactoryGirl.create(:user)
    good_tenant.tenant_memberships.create(:user_id => user.id)
    
    good_user_group = good_tenant.user_groups.create(:name => 'Example')
    evil_user_group = evil_tenant.user_groups.create(:name => 'Example')
    
    # Check the basics
    assert_equal 1, good_tenant.user_groups.count
    assert_equal 1, evil_tenant.user_groups.count
    assert_equal 1, good_tenant.users.count
    assert_equal 0, evil_tenant.users.count
    
    # Check if the user can become a member
    assert good_user_group.user_group_memberships.build(:user_id => user.id).valid?
    assert !evil_user_group.user_group_memberships.build(:user_id => user.id).valid?
  end

end
