class SwitchboardSerializer < ActiveModel::Serializer
  embed :ids, :include => true

  attributes :id, :name
  has_many :switchboard_entries, :key => :switchboard_entry_ids, :root => :switchboardEntrys
end
