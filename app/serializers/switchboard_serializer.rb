class SwitchboardSerializer < ActiveModel::Serializer
  attributes :id, :name

  embed :ids

  has_many :switchboard_entries, :key => :switchboard_entrys
end
