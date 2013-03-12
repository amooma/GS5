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

          # Indicate a new voicemail in the navigation bar.
          #
          PrivatePub.publish_to("/users/#{user.id}/messages/new", "$('#new_voicemail_or_fax_indicator').hide('fast').show('slow');")

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

  def fax_has_been_sent
    fax_document = FaxDocument.find(params[:id])

    if fax_document
      # push the partial to the webbrowser
      #
      new_html = ActionController::Base.helpers.escape_javascript(render_to_string("fax_documents/_fax_document", :layout => false, :locals => {:fax_document => fax_document}))
      Rails.logger.debug new_html
      PrivatePub.publish_to("/fax_documents/#{fax_document.id}", "$('#" + fax_document.id.to_s + ".fax_document').replaceWith('#{new_html}');")
    
      render(
            :status => 200,
            :layout => false,
            :content_type => 'text/plain',
            :text => "<!-- OK -->",
      )
    else
      render(
        :status => 501,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- ERRORS: #{errors.join(', ')} -->",
      )
    end
  end

  def fax
    if !params[:fax_account_id].blank?
      fax_account = FaxAccount.where(:id => params[:fax_account_id].to_i).first
      errors = Array.new()
      if fax_account
        fax_account.fax_documents.where(:state => 'received').each do |fax_document|

          pdf_file = fax_document.tiff_to_pdf

          if !pdf_file
            errors << "#{fax_document.tiff} cound not be converted"
            fax_document.state = 'unsuccessful'
            fax_document.save
            next
          end

          working_path, tiff_file = File.split(fax_document.tiff)
          if fax_document.store_dir != working_path
            FileUtils.mkdir(fax_document.store_dir)
            FileUtils.mv(fax_document.tiff, fax_document.store_dir)
            fax_document.tiff = "#{fax_document.store_dir}/#{tiff_file}"
          end

          fax_document.document = File.open(pdf_file)
          fax_document.state = 'successful'
          
          if fax_document.save
            Notifications.new_fax(fax_document).deliver
            @last_fax_document = fax_document

            begin
              File.delete(pdf_file)
            rescue => e
              logger.error "PDF fax file could not be deleted: #{pdf_file} => #{e.inspect}"
              errors << "#{pdf_file} cound not be deleted"
            end
            fax_document.save
            fax_document.render_thumbnails
          else
            errors << "#{fax_document.id} cound not be saved"
            fax_document.state = 'unsuccessful'
            fax_document.save
          end
        end
      else
        errors << "fax_account=#{params[:fax_account_id]} not found"
      end
       
      if errors.count == 0
        # Indicate a new fax in the navigation bar.
        #
        if @last_fax_document.fax_account.fax_accountable.class == User
          user = @last_fax_document.fax_account.fax_accountable
          PrivatePub.publish_to("/users/#{user.id}/messages/new", "$('#new_voicemail_or_fax_indicator').hide('fast').show('slow');")
        end

        render(
          :status => 200,
          :layout => false,
          :content_type => 'text/plain',
          :text => "<!-- OK -->",
        )
      else
       render(
          :status => 501,
          :layout => false,
          :content_type => 'text/plain',
          :text => "<!-- ERRORS: #{errors.join(', ')} -->",
        )
      end
    end
  end
end
