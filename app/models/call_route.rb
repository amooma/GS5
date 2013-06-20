class CallRoute < ActiveRecord::Base
  # https://github.com/rails/strong_parameters
  include ActiveModel::ForbiddenAttributesProtection

  ROUTING_TABLES = ['prerouting', 'outbound', 'inbound', 'dtmf']

  has_many :route_elements, :dependent => :destroy, :order => :position

  validates :name,
            :presence => true

  validates :routing_table,
            :presence => true,
            :inclusion => { :in => ROUTING_TABLES }

  acts_as_list :scope => '`routing_table` = \'#{routing_table}\''

  after_save :create_elements

  def to_s
    name.to_s
  end

  def move_up?
    return self.position.to_i > CallRoute.where(:routing_table => self.routing_table ).order(:position).first.position.to_i
  end

  def move_down?
    return self.position.to_i < CallRoute.where(:routing_table => self.routing_table ).order(:position).last.position.to_i
  end

  def self.factory_defaults_prerouting(country_code, national_prefix = '', international_prefix = '', trunk_access_code = '', area_code = '')
    CallRoute.where(:routing_table => "prerouting").destroy_all

    CallRoute.create_prerouting_entry('international call', [
      { :pattern => '^'+trunk_access_code+international_prefix+'([1-9]%d+)$', :replacement => '+%1', },
    ], 'phonenumber')

    CallRoute.create_prerouting_entry('national call', [
      { :pattern => '^'+trunk_access_code+national_prefix+'([1-9]%d+)$', :replacement => '+'+country_code+'%1', },
    ], 'phonenumber')

    if !trunk_access_code.blank? && !area_code.blank?
      CallRoute.create_prerouting_entry('local call', [
        { :pattern => '^'+trunk_access_code+'([1-9]%d+)$', :replacement => '+'+country_code+area_code+'%1', },
      ], 'phonenumber')
    end

    CallRoute.create_prerouting_entry('log in', [
      { :pattern => '^%*0%*$', :replacement => 'f-li', },
      { :pattern => '^%*0%*(%+?%d+)#*$', :replacement => 'f-li-%1', },
      { :pattern => '^%*0%*(%+?%d+)%*(%d+)#*$', :replacement => 'f-li-%1-%2', },
    ])

    CallRoute.create_prerouting_entry('log out', [
      { :pattern => '^#0#$', :replacement => 'f-lo', },
    ])

    CallRoute.create_prerouting_entry('toggle ACD membership', [
      { :pattern => '^%*5%*(%+?%d+)#$', :replacement => 'f-acdmtg-0-%1', },
    ])

    CallRoute.create_prerouting_entry('activate CLIP', [
      { :pattern => '^%*30#$', :replacement => 'f-clipon', },
    ])

    CallRoute.create_prerouting_entry('deactivate CLIP', [
      { :pattern => '^#30#$', :replacement => 'f-clipoff', },
    ])

    CallRoute.create_prerouting_entry('activate CLIR', [
      { :pattern => '^#31#$', :replacement => 'f-cliron', },
    ])

    CallRoute.create_prerouting_entry('deactivate CLIR', [
      { :pattern => '^%*31#$', :replacement => 'f-cliroff', },
    ])

    elements = [
      { :pattern => '^#31#(%+?[1-9]%d+)$', :replacement => 'f-dcliron-%1', }, 
      { :pattern => '^#31#'+trunk_access_code+international_prefix+'([1-9]%d+)$', :replacement => 'f-dcliron-+%1' },
      { :pattern => '^#31#'+trunk_access_code+national_prefix+'([1-9]%d+)$', :replacement => 'f-dcliron-+'+country_code+'%1' },
    ]

    if !trunk_access_code.blank? && !area_code.blank?
      elements << { :pattern => '^#31#'+trunk_access_code+'([1-9]%d+)$', :replacement => 'f-dcliron-+'+country_code+area_code+'%1' }
    end

    CallRoute.create_prerouting_entry('activate CLIR for call', elements)

    elements = [
      { :pattern => '^%*31#(%+?[1-9]%d+)$', :replacement => 'f-dcliroff-%1', }, 
      { :pattern => '^%*31#'+trunk_access_code+international_prefix+'([1-9]%d+)$', :replacement => 'f-dcliroff-+%1' },
      { :pattern => '^%*31#'+trunk_access_code+national_prefix+'([1-9]%d+)$', :replacement => 'f-dcliroff-+'+country_code+'%1' },
    ]

    if !trunk_access_code.blank? && !area_code.blank?
      elements << { :pattern => '^%*31#'+trunk_access_code+'([1-9]%d+)$', :replacement => 'f-dcliroff-+'+country_code+area_code+'%1' }
    end

    CallRoute.create_prerouting_entry('deactivate CLIR for call', elements)

    CallRoute.create_prerouting_entry('activate call waiting', [
      { :pattern => '^%*43#$', :replacement => 'f-cwaon', },
    ])

    CallRoute.create_prerouting_entry('deactivate call waiting', [
      { :pattern => '^#43#$', :replacement => 'f-cwaoff', },
    ])

    CallRoute.create_prerouting_entry('deactivate all call forwards', [
      { :pattern => '^#002#$', :replacement => 'f-cfoff', },
    ])

    CallRoute.create_prerouting_entry('delete all call forwards', [
      { :pattern => '^##002#$', :replacement => 'f-cfdel', },
    ])

    elements = [
      { :pattern => '^%*21#$', :replacement => 'f-cfu', },
      { :pattern => '^%*%*?21%*(%+?[1-9]%d+)#$', :replacement => 'f-cfu-%1', },
      { :pattern => '^%*%*?21%*'+trunk_access_code+international_prefix+'([1-9]%d+)#$', :replacement => 'f-cfu-+%1', },
      { :pattern => '^%*%*?21%*'+trunk_access_code+national_prefix+'([1-9]%d+)#$', :replacement => 'f-cfu-+'+country_code+'%1', },
    ]

    if !trunk_access_code.blank? && !area_code.blank?
      elements << { :pattern => '^%*%*?21%*'+trunk_access_code+'([1-9]%d+)#$', :replacement => 'f-cfu-+'+country_code+area_code+'%1' }
    end

    CallRoute.create_prerouting_entry('set unconditional call forwarding', elements)

    CallRoute.create_prerouting_entry('deactivate unconditional call forwarding', [
      { :pattern => '^#21#$', :replacement => 'f-cfuoff', },
    ])

    CallRoute.create_prerouting_entry('delete unconditional call forwarding', [
      { :pattern => '^##21#$', :replacement => 'f-cfudel', },
    ])

    elements = [
      { :pattern => '^%*61#$', :replacement => 'f-cfn', },
      { :pattern => '^%*%*?61%*'+trunk_access_code+international_prefix+'([1-9]%d+)#$', :replacement => 'f-cfn-+%1', },
      { :pattern => '^%*%*?61%*'+trunk_access_code+national_prefix+'([1-9]%d+)#$', :replacement => 'f-cfn-+'+country_code+'%1', },
      { :pattern => '^%*%*?61%*(%+?[1-9]%d+)#$', :replacement => 'f-cfn-%1', },
      { :pattern => '^%*%*?61%*'+trunk_access_code+international_prefix+'([1-9]%d+)%*(%d+)#$', :replacement => 'f-cfn-+%1-%2', },
      { :pattern => '^%*%*?61%*'+trunk_access_code+national_prefix+'([1-9]%d+)%*(%d+)#$', :replacement => 'f-cfn-+'+country_code+'%1-%2', },
      { :pattern => '^%*%*?61%*(%+?[1-9]%d+)%*(%d+)#$', :replacement => 'f-cfn-%1-%2', },
    ]

    if !trunk_access_code.blank? && !area_code.blank?
      elements << { :pattern => '^%*%*?61%*'+trunk_access_code+'([1-9]%d+)#$', :replacement => 'f-cfn-+'+country_code+area_code+'%1' }
      elements << { :pattern => '^%*%*?61%*'+trunk_access_code+'([1-9]%d+)%*(%d+)#$', :replacement => 'f-cfn-+'+country_code+area_code+'%1-%2' }
    end

    CallRoute.create_prerouting_entry('call forward if not answered', elements)

    CallRoute.create_prerouting_entry('deactivate call forward if not answered', [
      { :pattern => '^#61#$', :replacement => 'f-cfnoff', },
    ])

    CallRoute.create_prerouting_entry('delete call forward if not answered', [
      { :pattern => '^##61#$', :replacement => 'f-cfndel', },
    ])

    elements = [
      { :pattern => '^%*62#$', :replacement => 'f-cfo', },
      { :pattern => '^%*%*?62%*(%+?[1-9]%d+)#$', :replacement => 'f-cfo-%1', },
      { :pattern => '^%*%*?62%*'+trunk_access_code+international_prefix+'([1-9]%d+)#$', :replacement => 'f-cfo-+%1', },
      { :pattern => '^%*%*?62%*'+trunk_access_code+national_prefix+'([1-9]%d+)#$', :replacement => 'f-cfo-+'+country_code+'%1', },
    ]

    if !trunk_access_code.blank? && !area_code.blank?
      elements << { :pattern => '^%*%*?62%*'+trunk_access_code+'([1-9]%d+)#$', :replacement => 'f-cfo-+'+country_code+area_code+'%1' }
    end

    CallRoute.create_prerouting_entry('call forward if offline', elements)

    CallRoute.create_prerouting_entry('deactivate call forward if offline', [
      { :pattern => '^#62#$', :replacement => 'f-cfooff', },
    ])

    CallRoute.create_prerouting_entry('delete call forward if offline', [
      { :pattern => '^##62#$', :replacement => 'f-cfodel', },
    ])

    elements = [
      { :pattern => '^%*67#$', :replacement => 'f-cfb', },
      { :pattern => '^%*%*?67%*(%+?[1-9]%d+)#$', :replacement => 'f-cfb-%1', },
      { :pattern => '^%*%*?67%*'+trunk_access_code+international_prefix+'([1-9]%d+)#$', :replacement => 'f-cfb-+%1', },
      { :pattern => '^%*%*?67%*'+trunk_access_code+national_prefix+'([1-9]%d+)#$', :replacement => 'f-cfb-+'+country_code+'%1', },
    ]

    if !trunk_access_code.blank? && !area_code.blank?
      elements << { :pattern => '^%*%*?67%*'+trunk_access_code+'([1-9]%d+)#$', :replacement => 'f-cfb-+'+country_code+area_code+'%1' }
    end

    CallRoute.create_prerouting_entry('call forward if busy', elements)

    CallRoute.create_prerouting_entry('deactivate call forward if busy', [
      { :pattern => '^#67#$', :replacement => 'f-cfboff', },
    ])

    CallRoute.create_prerouting_entry('delete call forward if busy', [
      { :pattern => '^##67#$', :replacement => 'f-cfbdel', },
    ])


    CallRoute.create_prerouting_entry('redial', [
      { :pattern => '^%*66#$', :replacement => 'f-redial', },
    ])

    CallRoute.create_prerouting_entry('check voicemail', [
      { :pattern => '^%*98$', :replacement => 'f-vmcheck', },
      { :pattern => '^%*98#$', :replacement => 'f-vmcheck', },
      { :pattern => '^%*98%*(%+?%d+)#$', :replacement => 'f-vmcheck-%1', },
    ])

    CallRoute.create_prerouting_entry('acivate auto logout', [
      { :pattern => '^%*1337%*1%*1#$', :replacement => 'f-loaon', },
    ])

    CallRoute.create_prerouting_entry('deacivate auto logout', [
      { :pattern => '^%*1337%*1%*0#$', :replacement => 'f-loaoff', },
    ])
  end

  def self.create_prerouting_entry(name, elements, endpoint_type = 'dialplanfunction')
    call_route = CallRoute.create(:routing_table => 'prerouting', :name => name, :endpoint_type => endpoint_type)

    if !call_route.errors.any? then
      elements.each do |element|
        call_route.route_elements.create(
          :var_in => 'destination_number', 
          :var_out => 'destination_number', 
          :pattern => element[:pattern], 
          :replacement => element[:replacement], 
          :action => 'match', 
          :mandatory => false
        )
      end
    end
  end

  def endpoint_str
    "#{endpoint_type}=#{endpoint_id}"
  end

  def endpoint
    if self.endpoint_id.to_i > 0 
      begin
        return self.endpoint_type.camelize.constantize.where(:id => self.endpoint_id.to_i).first 
      rescue
        return nil
      end
    end
  end

  def xml
    @xml
  end

  def xml=(xml_string)
    @xml = xml_string
    if xml_string.blank?
      return
    end

    begin
      route_hash = Hash.from_xml(xml_string)
    rescue Exception => e
      errors.add(:xml, e.message)
      return
    end

    if route_hash['call_route'].class == Hash
      call_route = route_hash['call_route']
      self.routing_table = call_route['routing_table'].downcase
      self.name = call_route['name'].downcase
      self.position = call_route['position']
      self.endpoint_type = call_route['endpoint_type']
      endpoint_from_type_name(call_route['endpoint_type'], call_route['endpoint'])
      
      if route_hash['call_route']['route_elements'] && route_hash['call_route']['route_elements']['route_element']
        if route_hash['call_route']['route_elements']['route_element'].class == Hash
          @elements_array = [route_hash['call_route']['route_elements']['route_element']]
        else
          @elements_array = route_hash['call_route']['route_elements']['route_element']
        end
      end
    elsif route_hash['route_elements'].class == Hash && route_hash['route_elements']['route_element']
      if route_hash['route_elements']['route_element'].class == Hash
        @elements_array = [route_hash['route_elements']['route_element']]
      else
        @elements_array = route_hash['route_elements']['route_element']
      end
    end

  end

  def self.test_route(table, caller)
    arguments = ["'#{table}' table"]
    caller.each do |key, value|
      arguments << "'#{value}' '#{key}'"
    end

    require 'freeswitch_event'
    result = FreeswitchAPI.api_result(FreeswitchAPI.api('lua', 'test_route.lua', arguments.join(' ')))
    if result.blank? then
      return
    end

    return JSON.parse(result)
  end

  private
  def endpoint_from_type_name(endpoint_type, endpoint_name)
    endpoint_type = endpoint_type.to_s.downcase
    if endpoint_type == 'phonenumber'
      self.endpoint_type = 'PhoneNumber'
      self.endpoint_id = nil
    elsif endpoint_type == 'gateway'
      gateway = Gateway.where(:name => endpoint_name).first
      if gateway
        self.endpoint_type ='Gateway'
        self.endpoint_id = gateway.id
      end
    end
  end

  def create_elements
    if @elements_array && @elements_array.any?
      @elements_array.each do |element_hash|
        element = self.route_elements.create(element_hash)
      end
    end
  end

end
