class ConferenceInvitee < ActiveRecord::Base
  attr_accessible :pin, :speaker, :moderator, :phone_number, :phone_number_attributes

  belongs_to :conference
  belongs_to :phone_book_entry
  has_one :phone_number, :as => :phone_numberable, :dependent => :destroy
  accepts_nested_attributes_for :phone_number
  
  before_validation {
    if !self.pin.blank?
      self.pin = self.pin.to_s.gsub(/[^0-9]/, '')
    end
  }

  validates_presence_of :conference_id
  validates_presence_of :conference
  validates_presence_of :phone_number
  validates_length_of   :pin, :minimum => (GsParameter.get('MINIMUM_PIN_LENGTH').nil? ? 4 : GsParameter.get('MINIMUM_PIN_LENGTH')),
                        :allow_nil => true,
                        :allow_blank => true
                                  
  validates_inclusion_of :speaker, :in => [true, false]
  validates_inclusion_of :moderator, :in => [true, false]
    
  validate :uniqueness_of_phone_number_in_the_parent_conference
  validates_uniqueness_of :phone_book_entry_id, :scope => :conference_id, :allow_nil => true
  
  def to_s
    "ID #{self.id}"
  end

  private
  
  def uniqueness_of_phone_number_in_the_parent_conference
    if self.conference.conference_invitees.where('id != ?', self.id).count > 0 && 
       self.conference.conference_invitees.where('id != ?', self.id).map{|x| x.phone_number.number}.
            include?(self.phone_number.number)
       errors.add(:base, 'Phone number is not unique within the conference.')     
    end
  end
end
