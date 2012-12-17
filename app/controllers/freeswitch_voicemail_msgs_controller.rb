class FreeswitchVoicemailMsgsController < ApplicationController
  load_and_authorize_resource :sip_account
  load_and_authorize_resource :freeswitch_voicemail_msg, :through => [:sip_account]
  
  def index
  end
end
