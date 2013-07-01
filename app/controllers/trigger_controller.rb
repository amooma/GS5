class TriggerController < ApplicationController

  def voicemail
    if !params[:voicemail_account_id].blank?
      voicemail_account = VoicemailAccount.where(:id => params[:voicemail_account_id].to_i).first
      if voicemail_account
        voicemail_messages = voicemail_account.voicemail_messages.where(:notification => nil)
        if voicemail_messages.count > 0 
          if voicemail_account.voicemail_accountable.class == User
            user = voicemail_account.voicemail_accountable
          elsif voicemail_account.voicemail_accountable.class == SipAccount && voicemail_account.voicemail_accountable.sip_accountable.class == User
            user = voicemail_account.voicemail_accountable = voicemail_account.voicemail_accountable.sip_accountable
          end

          if user
            PrivatePub.publish_to("/users/#{user.id}/messages/new", "$('#new_voicemail_or_fax_indicator').hide('fast').show('slow');")
            PrivatePub.publish_to("/users/#{user.id}/messages/new", "document.title = '* ' + document.title.replace( '* ' , '');")
          end
        end

        email = voicemail_account.notify_to

        if !email.blank?
          voicemail_messages.each do |message|
            message.notification = false
            message.save
            if !File.exists?( message.file_path )
              next
            end
            message.notification = true

            if Notifications.new_voicemail(message, voicemail_account, email, voicemail_account.notification_setting('attachment')).deliver
              if voicemail_account.notification_setting('purge')
                message.delete
                next
              end
              message.save
              if voicemail_account.notification_setting('mark_read')
                message.mark_read
              end
            end
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

  def sip_account_update
    sip_account = SipAccount.find(params[:id])

    if sip_account.updated_at < Time.now

      # Push an update to sip_account.switchboard_entries
      #
      sip_account.switchboard_entries.each do |switchboard_entry|
        escaped_switchboard_entry_partial = ActionController::Base.helpers.escape_javascript(render_to_string("switchboard_entries/_switchboard_entry", :layout => false, :locals => {:switchboard_entry => switchboard_entry}))
        PrivatePub.publish_to("/switchboards/#{switchboard_entry.switchboard.id}", "$('#switchboard_entry_id_" + switchboard_entry.id.to_s + "').replaceWith('#{escaped_switchboard_entry_partial}');")
      end

      # Push an update to the needed switchboards
      #
      Switchboard.where(:user_id => sip_account.sip_accountable.id).each do |switchboard|
        if sip_account.call_legs.where(:sip_account_id => switchboard.user.sip_account_ids).any? || 
           sip_account.b_call_legs.where(:sip_account_id => switchboard.user.sip_account_ids).any?
          escaped_switchboard_partial = ActionController::Base.helpers.escape_javascript(render_to_string("switchboards/_current_user_dashboard", :layout => false, :locals => {:current_user => switchboard.user}))
          PrivatePub.publish_to("/switchboards/#{switchboard.id}", "$('.dashboard').replaceWith('#{escaped_switchboard_partial}');")
        end
      end

      sip_account.touch
    end

    render(
          :status => 200,
          :layout => false,
          :content_type => 'text/plain',
          :text => "<!-- OK -->",
    )
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
            begin
              FileUtils.mkdir(fax_document.store_dir)
            rescue => e
              logger.error "PDF fax directory not created: #{fax_document.store_dir} => #{e.inspect}"
            end

            begin
              FileUtils.mv(fax_document.tiff, fax_document.store_dir)
            rescue => e
              logger.error "PDF fax files not moved: #{fax_document.tiff} => #{e.inspect}"
            end

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
        if @last_fax_document && @last_fax_document.fax_account.fax_accountable.class == User
          user = @last_fax_document.fax_account.fax_accountable
          PrivatePub.publish_to("/users/#{user.id}/messages/new", "$('#new_voicemail_or_fax_indicator').hide('fast').show('slow');")
          PrivatePub.publish_to("/users/#{user.id}/messages/new", "document.title = '* ' + document.title.replace( '* ' , '');")
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
