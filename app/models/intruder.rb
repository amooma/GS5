class Intruder < ActiveRecord::Base
  attr_accessible :list_type, :key, :points, :bans, :ban_last, :ban_end, :contact_ip, :contact_port, :contact_count, :contact_last, :contacts_per_second, :contacts_per_second_max, :user_agent, :to_user, :comment

  LIST_TYPES = ['blacklist', 'whitelist']

  validates :list_type,
            :presence => true,
            :inclusion => { :in => LIST_TYPES }

  validates :key,
            :presence => true,
            :uniqueness => true

  validates :contact_ip,
            :presence => true,
            :uniqueness => true

  before_validation :set_key_if_empty

  after_create :check_if_new_entry_relevant
  after_update :check_if_update_relevant
  after_destroy :check_if_delete_relevant

  def to_s
    key
  end

  def whois(ip_address = self.contact_ip)
    if ! ip_address.blank?
      begin
        return Whois.whois(ip_address).to_s.gsub(/[^\u{0000}-\u{007F}]/, '')
      rescue
        return nil
      end
    end
  end

  def to_hash
    return {
      :key => self.key, 
      :points => self.points, 
      :bans => self.bans, 
      :received_port => self.contact_port, 
      :received_ip => self.contact_ip,
      :contact_count => self.contact_count, 
      :user_agent => self.user_agent, 
      :to_user => self.to_user, 
      :comment => self.comment,
      :date => DateTime.now.strftime('%Y-%m-%d %X')
    }
  end

  private
  def set_key_if_empty
    if self.key.blank?
      self.key = self.contact_ip
    end
  end

  def expand_variables(line, variables)
    return line.gsub(/\{([a-z_]+)\}/) do |m| 
      variables[$1.to_sym]
    end
  end

  def write_firewall_list
    firewall_blacklist_file = GsParameter.get('blacklist_file', 'perimeter', 'general')
    blacklist_entry_template = GsParameter.get('blacklist_file_entry', 'perimeter', 'general')
    whitelist_entry_template = GsParameter.get('whitelist_file_entry', 'perimeter', 'general')
    comment_template = GsParameter.get('blacklist_file_comment', 'perimeter', 'general')
    File.open(firewall_blacklist_file, 'w') do |file|
      Intruder.where(:list_type => ['whitelist', 'blacklist']).order('list_type DESC, contact_last ASC').all.each do |entry|
        if !whitelist_entry_template.blank? && entry.list_type == 'whitelist'
          if ! comment_template.blank?
            file.write(expand_variables(comment_template, entry.to_hash) + "\n")
          end
          file.write(expand_variables(whitelist_entry_template, entry.to_hash) + "\n")
        elsif !blacklist_entry_template.blank? && entry.list_type == 'blacklist' && entry.bans.to_i > 0
          if ! comment_template.blank?
            file.write(expand_variables(comment_template, entry.to_hash) + "\n")
          end
          file.write(expand_variables(blacklist_entry_template, entry.to_hash) + "\n")
        end
      end
    end
  end

  def restart_firewall
    command = GsParameter.get('ban_command', 'perimeter', 'general')
    if !command.blank?
      system expand_variables(command, self.to_hash)
    end
  end

  def check_if_update_relevant
    if key_changed? || contact_ip_changed? || list_type_changed? || bans_changed? || points_changed?
      if !GsParameter.get("#{self.list_type}_file_entry", 'perimeter', 'general').blank?
        write_firewall_list
        restart_firewall
      end
    end
  end

  def check_if_new_entry_relevant
    if !GsParameter.get("#{self.list_type}_file_entry", 'perimeter', 'general').blank?
      if self.list_type != 'blacklist' || self.bans.to_i > 0
        write_firewall_list
        restart_firewall
      end
    end
  end

  def check_if_delete_relevant
    if !GsParameter.get("#{self.list_type}_file_entry", 'perimeter', 'general').blank?
      if self.list_type != 'blacklist' || self.bans.to_i > 0
        write_firewall_list
        restart_firewall
      end
    end
  end 
end
