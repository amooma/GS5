# encoding: UTF-8

class FaxAccount < ActiveRecord::Base
  attr_accessible :name, :email, :station_id, :days_till_auto_delete, :phone_numbers_attributes, :retries

  # Validations:
  #
  validates_presence_of :fax_accountable_type, :fax_accountable_id
  validates_presence_of :fax_accountable
  validates_presence_of :name
  validates_presence_of :tenant_id
  validates_presence_of :tenant
  
  validates_numericality_of :days_till_auto_delete, :allow_nil => true
  validates_numericality_of :retries, :only_integer => true, :greater_than_or_equal_to => 0
  
  validates_uniqueness_of :name, :scope => [:fax_accountable_type, :fax_accountable_id]
    
  # Associations:
  #
  has_many :phone_numbers, :as => :phone_numberable, :dependent => :destroy
  has_many :fax_documents, :dependent => :destroy
  
  belongs_to :fax_accountable, :polymorphic => true
  belongs_to :tenant

  accepts_nested_attributes_for :phone_numbers
  
  # Hooks
  #
  before_validation :find_and_set_tenant_id
  before_validation :convert_umlauts
  
  def to_s
    name
  end
  
  private
  def require_at_least_one_phone_number
    if self.phone_numbers.count < 1
      errors.add(:base, 'needs at least one valid phone number')
    end  
  end
  
  def find_and_set_tenant_id
      if self.new_record? and self.tenant_id != nil
        return        
      else
        tenant = case self.fax_accountable_type
      	  when 'UserGroup' ; fax_accountable.tenant
      	  when 'User'      ; fax_accountable.current_tenant || fax_accountable.tenants.last
          when 'Tenant'    ; fax_accountable
      	  else nil
      	end
        self.tenant_id = tenant.id if tenant != nil
      end
  end

  def convert_umlauts
    self.name = self.name.sub(/ä/,'ae').
                            sub(/Ä/,'Ae').
                            sub(/ü/,'ue').
                            sub(/Ü/,'Ue').
                            sub(/ö/,'oe').
                            sub(/Ö/,'Oe').
                            sub(/ß/,'ss')
    self.name = self.name.gsub(/[^a-zA-Z0-9\-\,\:\.\+ ]/,'_')
    self.station_id = self.station_id.sub(/ä/,'ae').
                            sub(/Ä/,'Ae').
                            sub(/ü/,'ue').
                            sub(/Ü/,'Ue').
                            sub(/ö/,'oe').
                            sub(/Ö/,'Oe').
                            sub(/ß/,'ss')
    self.station_id = self.station_id.gsub(/[^a-zA-Z0-9\-\,\:\.\+ ]/,'_')
  end
  
end
