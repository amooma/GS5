class PageController < ApplicationController
  # load_and_authorize_resource :class => false  
  # CanCan doesn't work here really good because Page is not a resource.

  before_filter :if_fresh_system_then_go_to_wizard
  skip_before_filter :home_breadcrumb, :only => [:index]
  
  def index;end
  def conference;end
  def beginners_intro;end
  
  private
  def if_fresh_system_then_go_to_wizard
    if Tenant.count == 0 && User.count == 0
      # This is a brand new system. We need to run a setup first.
      redirect_to wizards_new_initial_setup_path
    else
      if current_user.nil?
        # You need to login first.
        redirect_to log_in_path, :alert => I18n.t('pages.controller.access_denied_login_first')
      end
    end
  end

end
