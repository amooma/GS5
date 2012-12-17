class TenantMembership < ActiveRecord::Base
  belongs_to :tenant
  belongs_to :user
    
  validates_presence_of :tenant
  validates_presence_of :user
  
  after_create :set_current_tenant_if_necessary

  # State Machine stuff
  default_scope where(:state => 'active')
  state_machine :initial => :active do
  end

  private
  # The first TenantMembership becomes the current_tenant by default.
  #
  def set_current_tenant_if_necessary
    if !self.user.current_tenant
      self.user.current_tenant = self.tenant
      self.user.save
    end
  end

end
