class SipAccountSerializer < ActiveModel::Serializer
  embed :ids, :include => true

  attributes :id, :auth_name, :caller_name, :sip_accountable_id, :is_registrated
  has_many :phone_numbers
  has_many :calls

  def is_registrated
    if object.registration
      true
    else
      false
    end
  end
end
