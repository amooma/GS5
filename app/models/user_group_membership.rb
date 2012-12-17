class UserGroupMembership < ActiveRecord::Base
  belongs_to :user
  belongs_to :user_group
  
  validates_uniqueness_of :user_id, :scope => :user_group_id
  validates_presence_of :user
  validates_presence_of :user_group
  
  validate :user_belongs_to_the_tenant_of_the_user_group
  
  # State Machine stuff
  default_scope where(:state => 'active')
  state_machine :initial => :active do
  end

  def to_s
    "#{self.user} / #{self.user_group}"
  end

  private
  def user_belongs_to_the_tenant_of_the_user_group
    if !self.user_group.tenant.users.include?(self.user)
      errors.add(:user_id, "not a member of the tenant which this group belongs to")
    end
  end
end
