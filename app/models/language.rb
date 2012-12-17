class Language < ActiveRecord::Base
  has_many :tenants
  has_many :users

  validates_presence_of :name
  validates_presence_of :code

  def to_s
    name
  end
end
