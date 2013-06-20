class VoicemailMessage < ActiveRecord::Base
  self.table_name = 'voicemail_msgs'
  self.primary_key = 'uuid'

  belongs_to :voicemail_account, :foreign_key => 'username', :primary_key => 'name', :readonly => true

  # Prevent objects from being destroyed
  def before_destroy
    raise ActiveRecord::ReadOnlyRecord
  end

  # Prevent objects from being deleted
  def self.delete_all
    raise ActiveRecord::ReadOnlyRecord
  end

  # Delete Message on FreeSWITCH over EventAPI
  def delete
    require 'freeswitch_event'
    result = FreeswitchAPI.execute('vm_delete', "#{self.username}@#{self.domain} #{self.uuid}");
  end

  # Alias for delete
  def destroy
    self.delete
  end

  # Mark Message read
  def mark_read(mark_read_or_unread = true)
    read_status = mark_read_or_unread ? 'read' : 'unread'
    require 'freeswitch_event'
    result = FreeswitchAPI.execute('vm_read', "#{self.username}@#{self.domain} #{read_status} #{self.uuid}");
  end

  def format_date(epoch, date_format = '%m/%d/%Y %H:%M', date_today_format = '%H:%M')
    if epoch && epoch > 0
      time = Time.at(epoch)
      if time.strftime('%Y%m%d') == Time.now.strftime('%Y%m%d')
        return time.in_time_zone.strftime(date_today_format)
      end
      return time.in_time_zone.strftime(date_format)
    end
  end

  def display_duration
    if self.message_len.to_i > 0
      minutes = (self.message_len / 1.minutes).to_i
      seconds = self.message_len - minutes.minutes.seconds
      return '%i:%02i' % [minutes, seconds]
    end
  end

  def phone_book_entry_by_number(number)
    begin
      voicemail_accountable = self.voicemail_account.voicemail_accountable
    rescue
      return nil
    end

    if ! voicemail_accountable
      return nil
    end

    if voicemail_accountable.class == SipAccount
      owner = voicemail_accountable.sip_accountable
    else
      owner = voicemail_accountable
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

end
