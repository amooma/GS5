class UserGroup < ActiveRecord::Base
  attr_accessible :name, :description
  
  belongs_to :tenant
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => :tenant_id
  
  validates_presence_of :tenant
  
  validates_length_of :name, :within => 1..50
  
  has_many :user_group_memberships, :dependent => :destroy, :uniq => true
  has_many :users, :through => :user_group_memberships

  has_many :gui_function_memberships, :dependent => :destroy
  has_many :gui_functions, :through => :gui_function_memberships

  has_many :phone_books, :as => :phone_bookable, :dependent => :destroy
  has_many :phone_book_entries, :through => :phone_books
    
  has_many :sip_accounts, :as => :sip_accountable, :dependent => :destroy
  
  has_many :conferences, :as => :conferenceable, :dependent => :destroy
  
  has_many :fax_accounts, :as => :fax_accountable, :dependent => :destroy
  
  acts_as_list :scope => :tenant_id
  
  def to_s
    name
  end
end
