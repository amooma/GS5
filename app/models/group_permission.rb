class GroupPermission < ActiveRecord::Base
  attr_accessible :group_id, :permission, :target_group_id

  PERMISSION_TYPES = ['pickup', 'presence']
  
  belongs_to :group
  belongs_to :target_group, :class_name => "Group"

  validates :target_group_id,
            :presence => true,
            :uniqueness => { :scope => [:group_id, :permission] }

  validates :target_group,
            :presence => true

  validates :permission,
            :presence => true,
            :uniqueness => { :scope => [:group_id, :target_group_id] },
            :inclusion => { :in => PERMISSION_TYPES }

  def to_s
    "#{self.permission} => #{self.target_group}"
  end
end
