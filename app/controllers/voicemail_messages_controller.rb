class VoicemailMessagesController < ApplicationController

  load_resource :voicemail_account
  load_and_authorize_resource :voicemail_message, :through => [:voicemail_account]

  before_filter :set_and_authorize_parent
  before_filter :spread_breadcrumbs

  helper_method :sort_column, :sort_descending
  
  before_filter { |controller|
    if ! params[:type].blank? then
      @type = params[:type].to_s
    end

    if ! params[:page].blank? then
      @pagination_page_number = params[:page].to_i
    end
  }

  def index
    @messages_count = @voicemail_account.voicemail_messages.count
    @messages_unread_count = @voicemail_account.voicemail_messages.where(:read_epoch => 0).count
    @messages_read_count = @messages_count - @messages_unread_count

    if @type == 'read'
      @voicemail_messages = @voicemail_account.voicemail_messages.where('read_epoch > 0').order(sort_column + ' ' + (sort_descending ? 'DESC' : 'ASC')).paginate(
                            :page => @pagination_page_number,
                            :per_page => GsParameter.get('DEFAULT_PAGINATION_ENTRIES_PER_PAGE')
                          )
    elsif @type == 'unread'
      @voicemail_messages = @voicemail_account.voicemail_messages.where(:read_epoch => 0).order(sort_column + ' ' + (sort_descending ? 'DESC' : 'ASC')).paginate(
                            :page => @pagination_page_number,
                            :per_page => GsParameter.get('DEFAULT_PAGINATION_ENTRIES_PER_PAGE')
                          )
    else
      @voicemail_messages = @voicemail_account.voicemail_messages.order(sort_column + ' ' + (sort_descending ? 'DESC' : 'ASC')).paginate(
                            :page => @pagination_page_number,
                            :per_page => GsParameter.get('DEFAULT_PAGINATION_ENTRIES_PER_PAGE')
                          )
    end

    @available_sip_account = available_sip_account()
  end

  def show
    respond_to do |format|
      format.wav {
        if @voicemail_message.file_path
          send_file @voicemail_message.file_path, :type => "audio/x-wav", 
            :filename => "#{Time.at(@voicemail_message.created_epoch).strftime('%Y%m%d-%H%M%S')}-#{@voicemail_message.cid_number}.wav"
        else
          render(
            :status => 404,
            :layout => false,
            :content_type => 'text/plain',
            :text => "<!-- Message not found -->",
          )
        end
      }
    end
  end

  def new
  end

  def create
  end

  def edit
  end

  def update
  end

  def destroy
    @voicemail_message.destroy
    m = method( :"#{@parent.class.name.underscore}_voicemail_messages_url" )
    redirect_to m.(), :notice => t('voicemail_messages.controller.successfuly_destroyed')
  end

  def destroy_multiple
    result = false
    if ! params[:selected_uuids].blank? then
      voicemail_messages = @voicemail_account.voicemail_messages.where(:uuid => params[:selected_uuids])
      voicemail_messages.each do |voicemail_message|
        result = voicemail_message.destroy
      end
    end

    m = method( :"#{@parent.class.name.underscore}_voicemail_messages_url" )
    if result
      redirect_to m.(), :notice => t('voicemail_messages.controller.successfuly_destroyed')
    else
      redirect_to m.()
    end
  end

  def available_sip_account
    voicemail_accountable = @voicemail_account.voicemail_accountable
    if voicemail_accountable.class == SipAccount
      return voicemail_accountable
    elsif voicemail_accountable.class == User
      return voicemail_accountable.sip_accounts.first
    end
  end

  def call
    phone_number = @voicemail_message.cid_number
    sip_account = self.available_sip_account
    if ! phone_number.blank? && sip_account && sip_account.registration
      sip_account.call(phone_number)
    end
    redirect_to(:back)
  end

  def mark_read
    @voicemail_message.mark_read
    redirect_to(:back)
  end

  def mark_unread
    @voicemail_message.mark_read(false)
    redirect_to(:back)
  end

  private
  def set_and_authorize_parent
    @parent = @voicemail_account

    authorize! :read, @parent

    @show_path_method = method( :"#{@parent.class.name.underscore}_voicemail_message_path" )
    @index_path_method = method( :"#{@parent.class.name.underscore}_voicemail_messages_path" )
    @new_path_method = method( :"new_#{@parent.class.name.underscore}_voicemail_message_path" )
    @edit_path_method = method( :"edit_#{@parent.class.name.underscore}_voicemail_message_path" )
  end

  def spread_breadcrumbs
    if @parent.class == SipAccount
     if @voicemail_account.voicemail_accountable.class == User
       add_breadcrumb t("#{@voicemail_account.voicemail_accountable.class.name.underscore.pluralize}.index.page_title"), method( :"tenant_#{@voicemail_account.voicemail_accountable.class.name.underscore.pluralize}_path" ).(@voicemail_account.tenant)
       add_breadcrumb @voicemail_account.voicemail_accountable, method( :"tenant_#{@voicemail_account.voicemail_accountable.class.name.underscore}_path" ).(@voicemail_account.tenant, @voicemail_account.voicemail_accountable)
     end
     add_breadcrumb t("voicemail_accounts.index.page_title"), method( :"#{@voicemail_account.voicemail_accountable.class.name.underscore}_voicemail_accounts_path" ).(@voicemail_account.voicemail_accountable)
     add_breadcrumb @voicemail_account, method( :"#{@voicemail_account.voicemail_accountable.class.name.underscore}_voicemail_account_path" ).(@voicemail_account.voicemail_accountable, @voicemail_account)
     add_breadcrumb t("voicemail_messages.index.page_title"), voicemail_account_voicemail_messages_path(@voicemail_account)
     if @voicemail_message && !@voicemail_message.new_record?
       add_breadcrumb @voicemail_message, voicemail_account_voicemail_message_path(@voicemail_account, @voicemail_message)
     end
    end
  end

  def sort_descending
    if sort_column == 'created_epoch' && params[:desc].to_s.blank?
      return true
    end
   
    params[:desc].to_s == 'true'
  end

  def sort_column
    VoicemailMessage.column_names.include?(params[:sort]) ? params[:sort] : 'created_epoch'
  end

end
