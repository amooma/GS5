class Address < ActiveRecord::Base
  attr_accessible :phone_book_entry_id, :line1, :line2, :street, :zip_code, :city, :country_id, :position, :uuid

  belongs_to :country

  validates_presence_of :uuid
  validates_uniqueness_of :uuid
end
