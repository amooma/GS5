class GsParameter < ActiveRecord::Base
  # https://github.com/rails/strong_parameters
  include ActiveModel::ForbiddenAttributesProtection  

  validates :name,
            :presence => true,
            :uniqueness => { :scope => [ :entity, :section ] }

  validates :class_type,
            :presence => true,
            :inclusion => { :in => ['String', 'Integer', 'Boolean', 'YAML', 'Nil'] }

  def self.get(wanted_variable, entity=nil, section=nil)
    if GsParameter.table_exists?
      if entity || section
        item = GsParameter.where(:name => wanted_variable, :entity => entity, :section => section).first
      else
        item = GsParameter.where(:name => wanted_variable).first
      end
      if item.nil? || item.class_type == 'Nil'
        return nil
      else
        return item.value.to_i if item.class_type == 'Integer'
        return item.value.to_s if item.class_type == 'String'
        if item.class_type == 'Boolean'
          return true if item.value == 'true'
          return false if item.value == 'false'
        end
        return YAML.load(item.value) if item.class_type == 'YAML'
      end
    else
      nil
    end
  end

  def to_s
    name
  end
end
