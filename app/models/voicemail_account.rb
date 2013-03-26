class VoicemailAccount < ActiveRecord::Base
  attr_accessible :uuid, :name, :active, :gs_node_id, :voicemail_accountable_type, :voicemail_accountable_id

  belongs_to :voicemail_accountable, :polymorphic => true
  has_many :voicemail_settings

  validates :name,
            :presence => true,
            :uniqueness => true

  validates :voicemail_accountable_id,
            :presence => true

  validates :voicemail_accountable_type,
            :presence => true

  def to_s
    "#{voicemail_accountable.to_s}: #{name}"
  end
end
