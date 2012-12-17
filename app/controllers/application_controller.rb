class ApplicationController < ActionController::Base
  
  protect_from_forgery

  before_filter :set_locale

  before_filter :go_to_setup_if_new_installation
  before_filter :home_breadcrumb
  
  helper_method :current_user
  
  helper_method :guess_local_ip_address
  helper_method :guess_local_host
  
  helper_method :'have_https?'

  helper_method :random_pin
  
  
  #TODO Add check_authorization. See
  # https://github.com/ryanb/cancan
  # https://github.com/ryanb/cancan/wiki/Ensure-Authorization
  # and Gemeinschaft 4
  
  # Generate a new name for an Object
  #
  def generate_a_new_name(parent, child = nil)
    if child
      i = parent.send(child.class.name.underscore.pluralize).count
      loop do
        i += 1
        if I18n.t("#{child.class.name.underscore.pluralize}.new_name_scaffold").include?('translation missing')
          @guess_a_new_name = I18n.t(child.class.name.underscore.pluralize + '.name') + " #{i}"
        else
          @guess_a_new_name = I18n.t("#{child.class.name.underscore.pluralize}.new_name_scaffold", :counter => i.to_s)
        end
        break unless parent.send(child.class.name.underscore.pluralize).where(:name => "#{@guess_a_new_name}").count > 0
      end
    else
      i = parent.class.count
      loop do
        i += 1
        if I18n.t("#{parent.class.name.underscore.pluralize}.new_name_scaffold").include?('translation missing')
          @guess_a_new_name = I18n.t(parent.class.name.underscore.pluralize + '.name') + " #{i}"
        else
          @guess_a_new_name = I18n.t("#{parent.class.name.underscore.pluralize}.new_name_scaffold", :counter => i.to_s)
        end
        break unless parent.class.where(:name => "#{@guess_a_new_name}").count > 0
      end
    end
    return @guess_a_new_name
  end

  # Generate a new random PIN
  #
  def random_pin
    if MINIMUM_PIN_LENGTH > 0
      (1..MINIMUM_PIN_LENGTH).map{|i| (0 .. 9).to_a.sample}.join
    end
  end
  
  # return the IP address (preferred) or hostname at which the
  # current request arrived
  def server_host
    return (
      request.env['SERVER_ADDR'] ||
      request.env['SERVER_NAME'] ||
      request.env['HTTP_HOST']
    )
  end
  
  def have_https?
    return Connectivity::port_open?( server_host(), 443 )
  end
  
  
  def guess_local_ip_address
    ret = nil
    begin
      ipsocket_addr_info = UDPSocket.open {|s| s.connect("255.255.255.254", 1); s.addr(false) }
      ret = ipsocket_addr_info.last if ipsocket_addr_info
    rescue
    end
    return ret
  end
  
  def guess_local_host
    ret = guess_local_ip_address()
    if ! ret
      begin
        if request
          ret = request.env['SERVER_NAME']
        end
      rescue
      end
    end
    if ret && [
      '',
      'localhost',
      '127.0.0.1',
      '0.0.0.0',
    ].include?(ret)
      ret = nil
    end
    return ret
  end
  
  rescue_from CanCan::AccessDenied do |exception|
    if @current_user
      redirect_to root_url, :alert => 'Access denied! Please ask your admin to grant you the necessary rights.'
    else
      if Tenant.count == 0 && User.count == 0
        # This is a brand new system. We need to run a setup first.
        redirect_to wizards_new_initial_setup_path
      else
        # You need to login first.
        redirect_to log_in_path, :alert => 'Access denied! You need to login first.'
      end
    end
  end
  
  private  
  
  def current_user  
    begin
      @current_user ||= User.find(session[:user_id]) if session[:user_id]
    rescue ActiveRecord::RecordNotFound
      session[:user_id] = nil
    end
    @current_user
  end  
  
  def go_to_setup_if_new_installation
    if Rails.env != 'test'
      if GemeinschaftSetup.all.count == 0
        redirect_to new_gemeinschaft_setup_path
      end
    end
  end
  
  def home_breadcrumb
    if current_user
      if current_user && Tenant.find(current_user.current_tenant_id)
        add_breadcrumb( current_user.current_tenant, tenant_path(current_user.current_tenant) )
      else
        add_breadcrumb I18n.t('pages.controller.index.name'), :root_path
      end
    end
  end

  def set_locale
    if current_user && Language.find(current_user.language_id)
      I18n.locale = current_user.language.code.downcase
    else
      logger.debug "* Accept-Language: #{request.env['HTTP_ACCEPT_LANGUAGE']}"
      I18n.locale = request.compatible_language_from(Language.all.map{|x| x.code})
    end
    logger.debug "* Locale set to '#{I18n.locale}'"
  end
  
end
