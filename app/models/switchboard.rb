class Switchboard < ActiveRecord::Base
  # https://github.com/rails/strong_parameters
  include ActiveModel::ForbiddenAttributesProtection

  validates :name,
            :presence => true,
            :uniqueness => {:scope => :user_id}

  belongs_to :user, :touch => true
  has_many :switchboard_entries, :dependent => :destroy
  has_many :sip_accounts, :through => :switchboard_entries

  def to_s
    self.name.to_s
  end
end
