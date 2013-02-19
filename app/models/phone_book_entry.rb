# encoding: UTF-8

class PhoneBookEntry < ActiveRecord::Base
  PHONE_NUMBER_NAMES = ['Phone', 'Office', 'Home', 'Mobile', 'Fax']

  before_save :run_phonetic_algorithm
  before_save :save_value_of_to_s
  
  attr_accessible :first_name, :middle_name, :last_name, :title, :nickname, :organization, :is_organization, :department, :job_title, :is_male, :birthday, :birth_name, :description, :homepage_personal, :homepage_organization, :twitter_account, :facebook_account, :google_plus_account, :xing_account, :linkedin_account, :mobileme_account, :image
  
  belongs_to :phone_book, :touch => true
  has_many :conference_invitees, :dependent => :destroy
  
  acts_as_list :scope => :phone_book
  
  validates_presence_of :phone_book
  
  validates_presence_of :last_name,
    :unless => Proc.new { |entry| entry.is_organization }
  
  validates_presence_of :organization,
    :if     => Proc.new { |entry| entry.is_organization }
  
  validates_inclusion_of :is_male, :in => [true, false, 1, '1', 'on'],
    :unless => Proc.new { |entry| entry.is_organization }
    
  has_many :phone_numbers, :as => :phone_numberable, :dependent => :destroy
  
  has_many :addresses, :dependent => :destroy
    
  # Avatar like photo  
  mount_uploader :image, ImageUploader  
  
  # TODO Validate homepage URLs and social media accounts.
  
  
  default_scope where(:state => 'active')
  
  # State Machine stuff
  state_machine :initial => :active do
  end
  
  def to_s
    if self.is_organization
      "#{self.organization}".strip
    else
      [self.last_name.strip, self.first_name.strip].join(', ')
    end
  end
  
  def self.koelner_phonetik(input)
    if input.blank?
      nil
    else
      # TODO: koelner_phonetik() needs to be tested.
  
      # Umwandeln in Grossbuchstaben
      phonetik = input.upcase.gsub(/[^A-ZÜüÖöÄäß]/,'').strip
  
      # Umwandeln anhand der Tabelle auf 
      # http://de.wikipedia.org/wiki/K%C3%B6lner_Verfahren
      phonetik = phonetik.gsub(/([XKQ])X/, '\1'+'8')
      phonetik = phonetik.gsub(/[DT]([CSZ])/, '8'+'\1')
      phonetik = phonetik.gsub(/C([^AHKOQUX])/, '8'+'\1')
      phonetik = phonetik.gsub(/^C([^AHKLOQRUX])/, '8'+'\1')
      phonetik = phonetik.gsub(/([SZ])C/, '\1'+'8')
      phonetik = phonetik.gsub(/[SZß]/, '8')
      phonetik = phonetik.gsub(/R/, '7')
      phonetik = phonetik.gsub(/[MN]/, '6')
      phonetik = phonetik.gsub(/L/, '5')
      phonetik = phonetik.gsub(/X/, '48')
      phonetik = phonetik.gsub(/([^SZ])C([AHKOQUX])/, '\1'+'4'+'\2'  )
      phonetik = phonetik.gsub(/^C([AHKLOQRUX])/, '4'+'\1')
      phonetik = phonetik.gsub(/[GKQ]/, '4')
      phonetik = phonetik.gsub(/PH/, '3H')
      phonetik = phonetik.gsub(/[FVW]/, '3')
      phonetik = phonetik.gsub(/[DT]([^CSZ])/, '2'+'\1')
      phonetik = phonetik.gsub(/[BP]/, '1')
      phonetik = phonetik.gsub(/H/, '')
      phonetik = phonetik.gsub(/[AEIJOUYÜüÖöÄä]/, '0')
  
      # Regeln für Buchstaben am Ende des Wortes
      phonetik = phonetik.gsub(/P/, '1')
      phonetik = phonetik.gsub(/[DT]/, '2')
      phonetik = phonetik.gsub(/C/, '8')
  
      # Entfernen aller doppelten
      phonetik = phonetik.gsub(/([0-9])\1+/, '\1')
  
      # Entfernen aller Codes "0" außer am Anfang.
      phonetik = phonetik.gsub(/^0/, 'X')
      phonetik = phonetik.gsub(/0/, '')
      phonetik = phonetik.gsub(/^X/, '0')
  
      phonetik
    end
  end
  
  private

  def run_phonetic_algorithm
    self.first_name_phonetic = PhoneBookEntry.koelner_phonetik(self.first_name) if self.first_name_changed?
    self.last_name_phonetic = PhoneBookEntry.koelner_phonetik(self.last_name) if self.last_name_changed?
    self.organization_phonetic = PhoneBookEntry.koelner_phonetik(self.organization) if self.organization_changed?
  end
  
  def save_value_of_to_s
    self.value_of_to_s = self.to_s
  end
  
end
