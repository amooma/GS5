class TriggerController < ApplicationController

  def voicemail
    if !params[:sip_account_id].blank?
      sip_account = SipAccount.where(:id => params[:sip_account_id].to_i).first
      if sip_account
        sip_account.voicemail_messages.where(:notification => nil).each do |message|
          message.notification = false
          message.save
          if !File.exists?( message.file_path )
            next
          end

          user = sip_account.sip_accountable
          if user.class != User
            next
          end

          if  user.email.blank?
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

        render(
          :status => 200,
          :layout => false,
          :content_type => 'text/plain',
          :text => "<!-- OK -->",
        )
      else
        render(
          :status => 404,
          :layout => false,
          :content_type => 'text/plain',
          :text => "<!-- Account not found -->",
        )
      end
    end
  end

  def fax
    if !params[:fax_account_id].blank?
      fax_account = FaxAccount.where(:id => params[:fax_account_id].to_i).first
      if fax_account
        fax_account.fax_documents.where(:state => 'received').each do |fax_document|

          pdf_file, tiff_file = fax_document.tiff_to_pdf

          if !pdf_file
            fax_document.state = 'unsuccessful'
            fax_document.save
            next
          end

          fax_document.document = File.open(pdf_file)
          fax_document.state = 'successful'
          
          if fax_document.save
            Notifications.new_fax(fax_document).deliver
            begin
              File.delete(tiff_file)
            rescue => e
              logger.error "Raw fax file could not be deleted: #{tiff_file} => #{e.inspect}" 
            end
            begin
              File.delete(pdf_file)
            rescue => e
              logger.error "PDF fax file could not be deleted: #{pdf_file} => #{e.inspect}"
            end
            fax_document.tiff = nil
            fax_document.save
            fax_document.render_thumbnails
          else
            fax_document.state = 'unsuccessful'
            fax_document.save
          end
        end

        render(
          :status => 200,
          :layout => false,
          :content_type => 'text/plain',
          :text => "<!-- OK -->",
        )
      else
        render(
          :status => 404,
          :layout => false,
          :content_type => 'text/plain',
          :text => "<!-- Account not found -->",
        )
      end
    end
  end
end
