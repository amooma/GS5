class GsParameter < ActiveRecord::Base
  validates :name,
            :presence => true,
            :uniqueness => true

  validates :value,
            :presence => true

  validates :class_type,
            :presence => true,
            :inclusion => { :in => ['String', 'Integer', 'Boolean', 'YAML'] }

  def generate_constant
    Kernel.const_set(self.name, self.value.to_i) if self.class_type == 'Integer'
    Kernel.const_set(self.name, self.value.to_s) if self.class_type == 'String'

    if self.class_type == 'Boolean'
      Kernel.const_set(self.name, true) if self.value == 'true'
      Kernel.const_set(self.name, false) if self.value == 'false'
    end

    Kernel.const_set(self.name, YAML.load(self.value)) if self.class_type == 'YAML'
  end

  def to_s
    name
  end
end
