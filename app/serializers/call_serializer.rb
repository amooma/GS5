class CallSerializer < ActiveModel::Serializer
  embed :uuids, :include => true

  attributes  :start_stamp, :destination, :callstate, :b_callstate, :b_caller_id_number, :sip_account_id
  attribute :uuid, :key => :id
end