class GuiFunction < ActiveRecord::Base
  attr_accessible :category, :name, :description, :gui_function_memberships_attributes

  has_many :gui_function_memberships, :dependent => :destroy
  has_many :user_groups, :through => :gui_function_memberships

  accepts_nested_attributes_for :gui_function_memberships

  validates :name, :presence => true, 
                   :format => { :with => /\A[a-z_0-9]+\z/, :message => "Only lower case letters allowed" },
                   :length => { :in => 3..255 },
                   :uniqueness => true

  def to_s
    self.name
  end

  def self.display?(function_name = nil, user)
    if function_name.blank? || GemeinschaftSetup.count == 0
      true
    else
      if !user || user.class != User || function_name.class != String
        false
      else
        function_name = function_name.downcase

        activated_gui_function_names = GuiFunctionMembership.where(:user_group_id => user.user_group_ids, :activated => true).map{|gui_function_membership| gui_function_membership.gui_function.name}.uniq
        deactivated_gui_function_names = GuiFunctionMembership.where(:user_group_id => user.user_group_ids, :activated => false).map{|gui_function_membership| gui_function_membership.gui_function.name}.uniq

        deactivated_gui_function_names = deactivated_gui_function_names - activated_gui_function_names

        if deactivated_gui_function_names.include?(function_name)
          false
        else
          true
        end
      end
    end
  end
end
