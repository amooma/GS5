# encoding: UTF-8

desc "Import inbound voicemail"

task :send_voicemail_notifications => :environment do
  VoicemailMessage.where(:notification => nil).each do |message|

    message.notification = false
    message.save
    if !File.exists?( message.file_path ) 
      $stderr.puts "File \"#{message.file_path}\" does not exist"
      next
    end

    sip_account = SipAccount.where(:auth_name => message.username).first
    if ! sip_account 
      $stderr.puts "SipAccount \"#{message.username}\" does not exist"
      next
    end

    user = sip_account.sip_accountable
    if user.class != User
      next
    end

    if  user.email.blank?
      $stderr.puts "no email address"
      next
    end

    voicemail_settings = sip_account.voicemail_setting
    if !voicemail_settings
      voicemail_settings = VoicemailSetting.new(:notify => user.send_voicemail_as_email_attachment, :attachment => user.send_voicemail_as_email_attachment, :mark_read => user.send_voicemail_as_email_attachment)
    end

    message.notification = voicemail_settings.notify
    if voicemail_settings.notify
      if Notifications.new_voicemail(message, voicemail_settings.attachment).deliver
        if voicemail_settings.purge
          message.delete
          next
        end
        message.save
        if voicemail_settings.mark_read
          message.mark_read
        end
      end
    else
      message.save
    end
  end
end
