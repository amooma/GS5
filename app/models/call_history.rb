class CallHistory < ActiveRecord::Base
  belongs_to :call_historyable, :polymorphic => true
  belongs_to :caller_account, :polymorphic => true
  belongs_to :callee_account, :polymorphic => true
  belongs_to :auth_account, :polymorphic => true

  validates :start_stamp,
            :presence => true
  
  def display_number
    if self.entry_type == 'dialed'
      return self.destination_number.to_s
    else
      return self.caller_id_number.to_s
    end
  end

  def display_name
    if self.entry_type == 'dialed'
      begin
        account = self.callee_account
      rescue
        account = nil
      end
      name_str = self.callee_id_name
    else
      begin
        account = self.caller_account
      rescue
        account = nil
      end
      name_str = self.caller_id_name
    end

    if name_str.blank?
      if account.class == SipAccount
        return account.caller_name.to_s
      elsif account
        return account.to_s
      end
    else
      return name_str.to_s
    end
  end

  def display_auth_account_name
    begin
      account = self.auth_account
    rescue
      return nil
    end

    if account.class == SipAccount
      return account.caller_name.to_s
    elsif account
      return account.to_s
    end
  end

  def display_image(image_size = :mini, phone_book_entry)
    if phone_book_entry
      image = phone_book_entry.image_url(image_size)
      if ! image.blank?
        return image
      end
    end
    
    begin 
      if self.entry_type == 'dialed'
        account = self.callee_account
      else
        account = self.caller_account
      end
    rescue
      return nil
    end

    if account.class == SipAccount && account.sip_accountable.class == User
      return account.sip_accountable.image_url(image_size).to_s
    end
  end

  def display_call_date(date_format, date_today_format)
    if self.start_stamp.to_date == Date.today
      return self.start_stamp.strftime(date_today_format)
    else
      return self.start_stamp.strftime(date_format)
    end
  end

  def display_duration
    if self.duration.to_i > 0
      minutes = (self.duration / 1.minutes).to_i
      seconds = self.duration - minutes.minutes.seconds
      return '%i:%02i' % [minutes, seconds]
    end
  end

  def phone_book_entry_by_number(number)
    begin
      call_historyable = self.call_historyable
    rescue
      return nil
    end

    if ! call_historyable
      return nil
    end

    if call_historyable.class == SipAccount
      owner = call_historyable.sip_accountable
    end

    if owner.class == User
      phone_books = owner.phone_books.all
      phone_books.concat(owner.current_tenant.phone_books.all)
    elsif owner.class == Tenant
      phone_books = owner.phone_books.all
    end

    if ! phone_books
      return nil
    end

    phone_books.each do |phone_book|
      phone_book_entry = phone_book.find_entry_by_number(number)
      if phone_book_entry
        return phone_book_entry
      end
    end

    return nil
      
  end

  def voicemail_message?
    begin 
      return self.call_historyable.voicemail_messages.where(:forwarded_by => self.caller_channel_uuid).any?
    rescue
      return nil
    end
  end

  def voicemail_message
    begin 
      return self.call_historyable.voicemail_messages.where(:forwarded_by => self.caller_channel_uuid).first
    rescue
      return nil
    end
  end

  def call_historyable_uuid
    begin
      return self.call_historyable.uuid
    rescue
      return nil
    end
  end

  def call_historyable_uuid=(uuid)
    begin
      return self.call_historyable_id = self.call_historyable_type.constantize.where(:uuid => uuid).first.id
    rescue
    end
  end

  def caller_account_uuid
    begin
      return self.caller_account.uuid
    rescue
      return nil
    end
  end

  def caller_account_uuid=(uuid)
    begin
      return self.caller_account_id = self.caller_account_type.constantize.where(:uuid => uuid).first.id
    rescue
    end
  end

  def callee_account_uuid
    begin
      return self.callee_account.uuid
    rescue
      return nil
    end
  end

  def callee_account_uuid=(uuid)
    begin
      return self.callee_account_id = self.callee_account_type.constantize.where(:uuid => uuid).first.id
    rescue
    end
  end

  def auth_account_uuid
    begin
      return self.auth_account.uuid
    rescue
      return nil
    end
  end

  def auth_account_uuid=(uuid)
    begin
      return self.auth_account_id = self.auth_account_type.constantize.where(:uuid => uuid).first.id
    rescue
    end
  end
end
