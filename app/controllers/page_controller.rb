class PageController < ApplicationController
  # load_and_authorize_resource :class => false  
  # CanCan doesn't work here really good because Page is not a resource.

  skip_before_filter :home_breadcrumb, :only => [:index]
  
  def index
    if current_user
      redirect_to [current_user.current_tenant, current_user]
    end
  end

  def help

  end

end
