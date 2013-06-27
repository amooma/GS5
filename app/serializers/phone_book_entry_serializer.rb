class PhoneBookEntrySerializer < ActiveModel::Serializer
  embed :ids, :include => true

  attributes :id, :first_name, :last_name, :organization, :search_result_display
  has_many :phone_numbers

  def search_result_display
    result = "#{object.last_name}, #{object.first_name}".strip.gsub(/^, /,'').gsub(/,$/,'')
    if result.blank?
      result = "#{object.organization}"
    end
    return result
  end
end
