class SystemMessage < ActiveRecord::Base
  attr_accessible :content

  belongs_to :user

  validates_presence_of :content
end
