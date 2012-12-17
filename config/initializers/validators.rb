ActiveRecord::Base.class_eval do
  
  def self.validate_mac_address( attr_names, options={} )
    validates_format_of( attr_names, {
      :with => /^ [0-9A-F]{2} (?: [0-9A-F]{2} ){5} $/x,
      :allow_blank => false,
      :allow_nil   => false,
    }.merge!( options ) )
  end
  
  def self.validate_ip_address( attr_names, options={} )
    validates_format_of( attr_names, {
      :with => /^
        (?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)
        (?:\.(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)){3}
      $/x,  # OPTIMIZE IPv6
      :allow_blank => false,
      :allow_nil   => false,
    }.merge!( options ) )
  end
  
  def self.validate_ip_port( attr_names, options={} )
    validates_numericality_of( attr_names, {
      :only_integer => true,
      :greater_than =>     0,
      :less_than    => 65536,
      :allow_nil    => false,
    }.merge!( options ) )
  end
  
  def self.validate_netmask( attr_names, options={} )
    configuration = {
      :allow_nil   => false,
      :allow_blank => false,
      :with =>
      /^(
         ((128|192|224|240|248|252|254)\.0\.0\.0)
        |(255\.(0|128|192|224|240|248|252|254)\.0\.0)
        |(255\.255\.(0|128|192|224|240|248|252|254)\.0)
        |(255\.255\.255\.(0|128|192|224|240|248|252|254))
      )$/x
    }
    configuration.merge!( options )
    validates_format_of( attr_names, configuration )
  end
  
  def self.validate_hostname_or_ip( attr_names, options={} )
    # Validate the server. This is the "host" rule from RFC 3261
    # (but the patterns for IPv4 and IPv6 addresses have been fixed here).
    configuration = {
      :allow_nil   => false,
      :allow_blank => false,
      :with =>
    /^
      (?:
        (?:
          (?:
            (?:
              [A-Za-z0-9] |
              [A-Za-z0-9] [A-Za-z0-9\-]* [A-Za-z0-9]
            )
            \.
          )*
          (?:
            [A-Za-z] |
            [A-Za-z] [A-Za-z0-9\-]* [A-Za-z0-9]
          )
          \.?
        )
        |
        (?:
          (?: 25[0-5] | 2[0-4]\d | 1\d\d | [1-9]?\d )
          (?: \. (?: 25[0-5] | 2[0-4]\d | 1\d\d | [1-9]?\d ) ){3}
        )
        |
        (
          (
            ( [0-9A-Fa-f]{1,4} [:] ){7} ( [0-9A-Fa-f]{1,4} | [:] )
          )|
          (
            ( [0-9A-Fa-f]{1,4} [:] ){6}
            (
              [:] [0-9A-Fa-f]{1,4} |
              (
                ( 25[0-5] | 2[0-4]\d | 1\d\d | [1-9]?\d )
                ( \. ( 25[0-5] | 2[0-4]\d | 1\d\d | [1-9]?\d ) ){3}
              ) | [:]
            )
          )|
          (
            ( [0-9A-Fa-f]{1,4} [:] ){5}
              (
                (
                  ( [:] [0-9A-Fa-f]{1,4} ){1,2}
                )|
                [:](
                  ( 25[0-5] | 2[0-4]\d | 1\d\d | [1-9]?\d )
                  ( \. ( 25[0-5] | 2[0-4]\d | 1\d\d | [1-9]?\d ) ){3}
                )|
                [:]
              )
          )|
          (
            ( [0-9A-Fa-f]{1,4} [:] ){4}
            (
              ( ( [:] [0-9A-Fa-f]{1,4} ){1,3} ) |
              (
                ( [:] [0-9A-Fa-f]{1,4} )? [:]
                (
                  ( 25[0-5] | 2[0-4]\d | 1\d\d | [1-9]?\d )
                  ( \. ( 25[0-5] | 2[0-4]\d | 1\d\d | [1-9]?\d ) ){3}
                )
              ) | [:]
            )
          )|
          (
            ( [0-9A-Fa-f]{1,4} [:] ){3}
            (
              ( ( [:] [0-9A-Fa-f]{1,4} ){1,4} ) |
              (
                ( [:] [0-9A-Fa-f]{1,4} ){0,2} [:]
                (
                  ( 25[0-5] | 2[0-4]\d | 1\d\d | [1-9]?\d )
                  ( \. ( 25[0-5] | 2[0-4]\d | 1\d\d | [1-9]?\d ) ){3}
                )
              ) | [:]
            )
          )|
          (
            ( [0-9A-Fa-f]{1,4} [:] ){2}
            (
              ( ( [:] [0-9A-Fa-f]{1,4} ){1,5} ) |
              (
                ( [:] [0-9A-Fa-f]{1,4} ){0,3} [:]
                (
                  ( 25[0-5] | 2[0-4]\d | 1\d\d | [1-9]?\d )
                  ( \. ( 25[0-5] | 2[0-4]\d | 1\d\d | [1-9]?\d ) ){3}
                )
              ) | [:]
            )
          )|
          (
            ( [0-9A-Fa-f]{1,4} [:] ){1}
            (
              ( ( [:] [0-9A-Fa-f]{1,4} ){1,6} ) |
              (
                ( [:] [0-9A-Fa-f]{1,4} ){0,4} [:]
                (
                  ( 25[0-5] | 2[0-4]\d | 1\d\d | [1-9]?\d )
                  ( \. ( 25[0-5] | 2[0-4]\d | 1\d\d | [1-9]?\d ) ){3}
                )
              ) | [:]
            )
          )|
          (
            [:]
            (
              ( ( [:] [0-9A-Fa-f]{1,4} ){1,7} ) |
              (
                ( [:] [0-9A-Fa-f]{1,4} ){0,5} [:]
                (
                  ( 25[0-5] | 2[0-4]\d | 1\d\d | [1-9]?\d )
                  ( \. ( 25[0-5] | 2[0-4]\d | 1\d\d | [1-9]?\d ) ){3}
                )
              ) | [:]
            )
          )
        )
      )
    $/x
    }
    configuration.merge!( options )
    validates_format_of( attr_names, configuration )
  end
  
  # Validate SIP username. This is the "user" rule from RFC 3261.
  def self.validate_username( attr_names, options={} )
    configuration = {
      :allow_nil   => false,
      :allow_blank => false,
      :with =>
      /^
        (?:
          (?:
            [A-Za-z0-9] |
            [\-_.!~*'()]
          ) |
          %[0-9A-F]{2} |
          [&=+$,;?\/]
        ){1,255}
      $/x
    } 
    configuration.merge!( options )
    validates_format_of( attr_names, configuration )
  end
  
  # Validate SIP password.
  def self.validate_sip_password( attr_names, options={} )
    configuration = {
      :allow_nil   => true,
      :allow_blank => true,
      :with =>
      /^
        (?:
          (?:
            [A-Za-z0-9] |
            [\-_.!~*'()]
        ) |
        %[0-9A-F]{2} |
        [&=+$,]
      ){0,255}
      $/x
    }
    configuration.merge!( options )
    validates_format_of( attr_names, configuration )
  end
  
end



module CustomValidators
  
  # Validates a URL.
  # TODO Convert this into a proper ActiveRecord validator.
  #
  def self.validate_url( url_str )
    return false if url_str.blank?
    require 'uri'
    begin
      uri = URI.parse( url_str )
      return false if !  uri.absolute?
      return false if !  uri.hierarchical?
      return false if !( uri.is_a?( URI::HTTP ) || uri.is_a?( URI::HTTPS ) )
    rescue URI::InvalidURIError
      return false
    end
    return true
  end
  
end

