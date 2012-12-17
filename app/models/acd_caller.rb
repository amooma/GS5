class AcdCaller < ActiveRecord::Base
  attr_accessible :channel_uuid, :automatic_call_distributor_id, :status, :enter_time, :agent_answer_time, :callback_number, :callback_attempts

  has_one :channel, :class_name => 'FreeswitchChannel', :foreign_key => 'uuid', :primary_key => 'channel_uuid'
  belongs_to :automatic_call_distributor
end
