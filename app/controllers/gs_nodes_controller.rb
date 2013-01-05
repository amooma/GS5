class GsNodesController < ApplicationController
  
  load_and_authorize_resource :gs_node, :only => [:index, :show, :new, :create, :edit, :update, :destroy]

  before_filter :spread_breadcrumbs

  def index

  end

  def show

  end

  def new
    @gs_node = GsNode.new
    @gs_node.push_updates_to = true
    @gs_node.accepts_updates_from = true
    @gs_node.element_name = 'gs_cluster_sync_log_entry'
  end

  def create
    @gs_node = GsNode.new(params[:gs_node])
    if @gs_node.save
      redirect_to @gs_node, :notice => t('gs_nodes.controller.successfuly_created')
    else
      render :new
    end
  end

  def edit
    @gs_node = GsNode.find(params[:id])
  end

  def update
    @gs_node = GsNode.find(params[:id])
    if @gs_node.update_attributes(params[:gs_node])
      redirect_to @gs_node, :notice  => t('gs_nodes.controller.successfuly_updated')
    else
      render :edit
    end
  end

  def destroy
    @gs_node = GsNode.find(params[:id])
    @gs_node.destroy
    redirect_to gs_nodes_url, :notice => t('gs_nodes.controller.successfuly_destroyed')
  end

  def sync
    if !GsNode.where(:ip_address => request.remote_ip).first
      render(
        :status => 404,
        :layout => false,
        :content_type => 'text/plain',
        :text => "<!-- Node not found -->",
      )
      return
    end

    if ! params[:newer].blank?
      @newer_as = Time.at(params[:newer].to_i)
    else
      @newer_as = Time.at(0)
    end

    if ! params[:class].blank?
      @request_class = params[:class].to_s
    else
      @request_class = '';
    end

    @node = GsNode.where(:ip_address => GsParameter.get('HOMEBASE_IP_ADDRESS')).first
    
    if @request_class.blank? || @request_class == "tenants"
      @tenants = Tenant.where('updated_at > ?', @newer_as)
    end

    if @request_class.blank? || @request_class == "user_groups"
      @user_groups = UserGroup.where('updated_at > ?', @newer_as)
    end

    if @request_class.blank? || @request_class == "users"
      @users = User.where('updated_at > ?', @newer_as)
    end

    if @request_class.blank? || @request_class == "user_group_memberships"
      @user_group_memberships = UserGroupMembership.where('updated_at > ?', @newer_as)
    end
    
    if @request_class.blank? || @request_class == "sip_accounts"
      @sip_accounts = SipAccount.where('updated_at > ?',@newer_as)
    end

    if @request_class.blank? || @request_class == "conferences"
      @conferences = Conference.where('updated_at > ?', @newer_as)
    end

    if @request_class.blank? || @request_class == "fax_accounts"
      @fax_accounts = FaxAccount.where('updated_at > ?', @newer_as)
    end

    if @request_class.blank? || @request_class == "phone_books"
      @phone_books = PhoneBook.where('updated_at > ?',@newer_as)
    end

    if @request_class.blank? || @request_class == "phone_book_entries"
      @phone_book_entries = PhoneBookEntry.where('updated_at > ?',@newer_as)
    end

    if @request_class.blank? || @request_class == "phone_numbers"
      @phone_numbers = PhoneNumber.where('updated_at > ?', @newer_as)
    end

    if @request_class.blank? || @request_class == "call_forwards"
      @call_forwards = CallForward.where('updated_at > ?', @newer_as)
    end

    if @request_class.blank? || @request_class == "softkeys"
      @softkeys = Softkey.where('updated_at > ?', @newer_as)
    end
    
    if @request_class.blank? || @request_class == "ringtones"
      @ringtones = Ringtone.where('updated_at > ?', @newer_as)
    end

    if @request_class.blank? || @request_class == "conference_invitees"
      @conference_invitees = ConferenceInvitee.where('updated_at > ?', @newer_as)
    end

    if @request_class == "fax_documents"
      @fax_documents = FaxDocument.where('updated_at > ?', @newer_as)
    end

    if @request_class == "call_histories"
      @call_histories = CallHistory.where('updated_at > ?', @newer_as)
    end

    if @request_class.blank? || @request_class == "deleted_items"
      @deleted_items = Array.new
      deleted_items_log = GsClusterSyncLogEntry.where('action = "destroy" AND updated_at > ?', @newer_as)
      deleted_items_log.each do |deleted_item_log_entry|
        content = JSON(deleted_item_log_entry.content)
        content['class_name'] = deleted_item_log_entry.class_name
        if content['uuid']
          @deleted_items << content
        end
      end
    end

    if params[:image].to_s == 'false'
      @image_include = false
    else
      @image_include = true
    end

  end

  private

  def spread_breadcrumbs
    if @gs_node
      add_breadcrumb t("gs_nodes.index.page_title"), gs_nodes_path

      if @gs_node && !@gs_node.new_record?
        add_breadcrumb @gs_node, gs_node_path(@gs_node)
      end
    end
  end
end
