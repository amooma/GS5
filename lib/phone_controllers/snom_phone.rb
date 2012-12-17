class SnomPhone
  
  attr_accessor :phone, :destination_number
  
  def initialize( attributes = {} )
   @phone               = attributes[:phone]
   @destination_number  = attributes[:destination_number]
  end
  
  def initiate_call
    # TODO Initiate a new call to the destination_number.
    # Do what ever it takes.
    42
  end
  
  # persisted is important not to get "undefined method
  # `to_key' for" error
  # -- Huh? #TODO Add a better description.
  def persisted?
    false
  end
  
end
