class SwitchboardSerializer < ActiveModel::Serializer
  embed :ids, :include => true

  attributes :id, :name, :show_avatars, :blind_transfer_activated, :attended_transfer_activated, :search_activated
  has_many :switchboard_entries
  has_many :sip_accounts, :through => :switchboard_entries
  has_many :phone_numbers
  has_many :active_calls
  has_many :dispatchable_incoming_calls
end
