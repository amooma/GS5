class ChangePerimeterBlacklistEntry < ActiveRecord::Migration
  def up
    blacklist_file_entry = GsParameter.where(:entity => 'perimeter', :section => 'general', :name => 'blacklist_file_entry').first
    if blacklist_file_entry
      blacklist_file_entry.update_attributes(:value => 'DROP            net:{received_ip}        all                     udp     5060', :class_type => 'String')
    end
  end

  def down
    blacklist_file_entry = GsParameter.where(:entity => 'perimeter', :section => 'general', :name => 'blacklist_file_entry').first
    if blacklist_file_entry
      blacklist_file_entry.update_attributes(:value => '{received_ip} udp 5060', :class_type => 'String')
    end
  end
end
