class PagerGroupSerializer < ActiveModel::Serializer
  embed :ids, :include => true

  attributes :id, :sip_account_id, :callback_url

  has_many :pager_group_destinations
end
