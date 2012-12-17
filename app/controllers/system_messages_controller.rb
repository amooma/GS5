class SystemMessagesController < ApplicationController
  load_and_authorize_resource :user
  load_and_authorize_resource :system_message, :through => [:user]

  def index
   @system_messages = @system_messages.where(:created_at => Time.now - 6.hours .. Time.now)
  end

  def show
  end

  def new
    @system_message = @user.system_messages.build
  end

  def create
    @system_message = @user.system_messages.build(params[:system_message])
    if @system_message.save
      # Push the new message via AJAX to the browser.
      #
      # PrivatePub.publish_to("/users/#{@system_message.user.id}/system_messages", 
      #                       "$('#system_message').empty();$('#system_message').append('<span class=\"created_at\">#{(I18n.l @system_message.created_at, :format => :short )}</span> #{@system_message.content}');$('#system_message_display').fadeIn();"
      #                       )

      redirect_to user_system_message_path(@user, @system_message), :notice => t('system_messages.controller.successfuly_created')
    else
      render :new
    end
  end
end
