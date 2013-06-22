class Cdr < ActiveRecord::Base
  self.table_name = 'cdrs'
  self.primary_key = 'uuid'

  belongs_to :account
  belongs_to :bleg_account
  belongs_to :forwarding_account


  def self.seconds_to_minutes_seconds(call_seconds)
    if call_seconds.to_i > 0
      minutes = (call_seconds / 1.minutes).to_i
      seconds = call_seconds - minutes.minutes.seconds
      return '%i:%02i' % [minutes, seconds]
    end
  end
end
