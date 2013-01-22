class PhoneBook < ActiveRecord::Base
  attr_accessible :name, :description, :uuid
  
  belongs_to :phone_bookable, :polymorphic => true, :touch => true
  has_many :phone_book_entries, :dependent => :destroy
  
  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [ :phone_bookable_type, :phone_bookable_id ] 
  
  validates_length_of :name, :within => 1..50

  validates_presence_of :uuid
  validates_uniqueness_of :uuid

  # State Machine stuff
  default_scope where(:state => 'active')
  state_machine :initial => :active do
  end
  
  def to_s
    name
  end

  def find_entry_by_number(number)
    phone_book_entries_ids = self.phone_book_entries.map{|phone_book_entry| phone_book_entry.id}
    
    phone_number = PhoneNumber.where(:phone_numberable_id => phone_book_entries_ids, :phone_numberable_type => 'PhoneBookEntry', :number => number).first

    if phone_number
      return phone_number.phone_numberable
    end
  end
end
