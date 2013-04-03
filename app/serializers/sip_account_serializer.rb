class SipAccountSerializer < ActiveModel::Serializer
  embed :ids, :include => true

  attributes :id, :auth_name, :caller_name, :sip_accountable_id
  has_many :phone_numbers
end
