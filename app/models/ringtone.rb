class Ringtone < ActiveRecord::Base
  attr_accessible :audio, :bellcore_id
  CORE_RINGTONES_AVAILABLE = {
    'Silence' => 0,
    'Ringtone 1' => 1,
    'Ringtone 2' => 2,
    'Ringtone 3' => 3,
    'Ringtone 4' => 4,
    'Ringtone 5' => 5,
    'Ringtone 6' => 6,
    'Ringtone 7' => 7,
    'Ringtone 8' => 8,
    'Ringtone 9' => 9,
    'Ringtone 10' => 10,
  }
  
  mount_uploader :audio, AudioUploader
  validates_presence_of :audio, :if => Proc.new{ |ringtone| ringtone.bellcore_id.blank? }
  validates_presence_of :ringtoneable_type
  validates_presence_of :ringtoneable_id
  validates_presence_of :ringtoneable
  validates_uniqueness_of :ringtoneable_id, :scope => [:ringtoneable_type]
  
  belongs_to :ringtoneable, :polymorphic => true

  def to_s
    CORE_RINGTONES_AVAILABLE.index(self.bellcore_id)
  end
end
