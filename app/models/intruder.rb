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

  def self.write_firewall_blacklist
    firewall_blacklist_file = GsParameter.get('blacklist_file', 'perimeter', 'general')
    entry_template = GsParameter.get('blacklist_file_entry', 'perimeter', 'general')
    comment_template = GsParameter.get('blacklist_file_comment', 'perimeter', 'general')
    File.open(firewall_blacklist_file, 'w') do |file|
      Intruder.where(:list_type => 'blacklist').where('bans > 0').all.each do |entry|
        if ! comment_template.blank?
          file.write(self.expand_variables(comment_template, entry.to_hash) + "\n")
        end
        file.write(self.expand_variables(entry_template, entry.to_hash) + "\n")
      end
    end
  end

  def self.expand_variables(line, variables)
    return line.gsub(/\{([a-z_]+)\}/) do |m| 
      variables[$1.to_sym]
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
end
