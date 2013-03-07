class Group < ActiveRecord::Base
  attr_accessible :name, :active, :comment

  has_many :group_memberships, :dependent => :destroy
  has_many :group_permissions, :dependent => :destroy
  has_many :permittances, :foreign_key => :target_group_id, :class_name => "GroupPermission", :dependent => :destroy

  validates :name,
            :presence => true

  def to_s
    self.name
  end

  def permission_targets(permission)
    group_permissions.where(:permission => permission).pluck(:target_group_id)
  end

  def has_permission(target_type, target_id, permission)
    target_group_ids = GroupMembership.where(:item_id => target_id, :item_type => target_type).pluck(:group_id)
    return group_permissions.where(:permission => permission, :target_group_id => target_group_ids).first != nil
  end

  def self.union(sets=[])
    group_ids = []
    sets.each do |set|
      group_ids = group_ids + set
    end

    return group_ids.uniq
  end
end
