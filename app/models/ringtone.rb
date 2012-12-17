class Ringtone < ActiveRecord::Base
  attr_accessible :audio, :bellcore_id
  
  mount_uploader :audio, AudioUploader
  validates_presence_of :audio, :if => Proc.new{ |ringtone| ringtone.bellcore_id.blank? }
  validates_presence_of :ringtoneable_type
  validates_presence_of :ringtoneable_id
  validates_presence_of :ringtoneable
  
  belongs_to :ringtoneable, :polymorphic => true

  def to_s
    self.bellcore_id.to_s
  end
end
