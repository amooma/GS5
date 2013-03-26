class SwitchboardEntrySerializer < ActiveModel::Serializer
  attributes :id, :name

  has_many :phone_numbers, embed: :ids
end
