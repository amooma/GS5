class SwitchboardSerializer < ActiveModel::Serializer
  embed :ids, :include => true

  attributes :id, :name
  has_many :switchboard_entries
  has_many :sip_accounts, :through => :switchboard_entries
  has_many :phone_numbers
end
