class FaxResolution < ActiveRecord::Base
  validates_presence_of :name
  validates_presence_of :resolution_value
  
  validates_uniqueness_of :name
  validates_uniqueness_of :resolution_value
  
  has_many :fax_documents, :dependent => :destroy
  
  acts_as_list
  
  def to_s
    self.name
  end
end
