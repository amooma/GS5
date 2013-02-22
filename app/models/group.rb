class Group < ActiveRecord::Base
  attr_accessible :name, :active, :comment

  has_many :group_memberships, :dependent => :destroy
  has_many :group_permissions, :dependent => :destroy
  has_many :permittances, :foreign_key => :target_group_id, :class_name => "GroupPermission", :dependent => :destroy

  def to_s
    self.name
  end
end
