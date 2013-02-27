class GroupMembership < ActiveRecord::Base
  attr_accessible :group_id, :item_type, :item_id

  belongs_to :group
  belongs_to :item, :polymorphic => true

  validates :item_id,
            :presence => true,
            :uniqueness => { :scope => [:group_id, :item_type] }

  validates :item_type,
            :presence => true,
            :uniqueness => { :scope => [:group_id, :item_id] }

  validate  :validate_item_type_consitency

  validates :item,
            :presence => true

  def to_s
    "#{self.item_type}: #{self.item}"
  end

  def item_type_allowed
    fist_item = self.group.group_memberships.first.try(:item)
    if fist_item
      return fist_item.class.name
    end
  end

  def validate_item_type_consitency
    type_allowed = self.item_type_allowed
    if type_allowed && type_allowed != self.item_type
      errors.add(:item_type, "must be of type: #{type_allowed}")
    end
  end
end
