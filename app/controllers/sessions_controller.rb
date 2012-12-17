class SessionsController < ApplicationController
  
  before_filter :redirect_to_https
  skip_before_filter :home_breadcrumb
  
  def new
  end  
  
  def create  
    user = User.find_by_email(params[:sessions][:login_data].downcase.strip)
    if user.nil?
      user = User.find_by_user_name(params[:sessions][:login_data].downcase.strip)
    end 
    if user && user.authenticate(params[:sessions][:password])  
      session[:user_id] = user.id  
      redirect_to tenant_user_path(user.current_tenant, user), :notice => t('sessions.controller.successfully_created', :resource => user)
    elsif user && !user.email.blank? && params[:sessions][:reset_password] =~ (/(1|t|y|yes|true)$/i)
      password = SecureRandom.base64(8)[0..7]
      if user.update_attributes(:password => password)
        Notifications.new_password(user, password).deliver
        flash.now.notice = t('sessions.flash_messages.password_recovery_successful', :resource => user) 
      else
        flash.now.alert = t('sessions.flash_messages.password_recovery_failed', :resource => user) 
      end
      render "new"  
    else
      flash.now.alert = t('sessions.flash_messages.invalid_email_or_password', :resource => user) 
      render "new"  
    end  
  end
    
  def destroy  
    session[:user_id] = nil
    redirect_to root_url, :notice => t('sessions.controller.successfully_destroyed')  
  end

  private
  def redirect_to_https
    if GUI_REDIRECT_HTTPS and ! request.ssl?
      redirect_to :protocol => "https://"
    end
  end
  
end
