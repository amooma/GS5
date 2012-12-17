class SoftkeyFunction < ActiveRecord::Base
  validates_presence_of :name

  validates_uniqueness_of :name

  acts_as_list

  default_scope order(:position)

  def to_s
    self.name
  end
end
