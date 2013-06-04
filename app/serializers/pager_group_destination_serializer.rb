class PagerGroupDestinationSerializer < ActiveModel::Serializer
  embed :ids, :include => true
end
