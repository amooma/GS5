class FaxDocumentsController < ApplicationController
  load_and_authorize_resource :fax_account
  load_and_authorize_resource :fax_document, :through => [:fax_account]
  
  before_filter :spread_breadcrumbs
  
  def index
    @fax_documents = @fax_documents.order(:created_at).reverse_order
  end

  def show
    respond_to do |format|
      @fax_document = FaxDocument.find(params[:id])
      format.html
      format.xml { render :xml => @fax_document }
      format.pdf {
        caller_number = @fax_document.caller_id_number.to_s.gsub(/[^0-9]/, '')
        if caller_number.blank?
          caller_number = 'anonymous'
        end

        if @fax_document.document.path
          send_file @fax_document.document.path, :type => "application/pdf", 
            :filename => "#{@fax_document.created_at.strftime('%Y%m%d-%H%M%S')}-#{caller_number}.pdf"
        else
          render(
            :status => 404,
            :layout => false,
            :content_type => 'text/plain',
            :text => "<!-- Document not found -->",
          )
        end
      }
    end
  end

  def new
    @fax_document = @fax_account.fax_documents.build
    @phone_number = @fax_document.build_destination_phone_number
  end

  def create
    @fax_document = @fax_account.fax_documents.build(params[:fax_document])
    @fax_document.retry_counter = @fax_account.retries
    if @fax_document.save
      @fax_document.queue_for_sending!
      redirect_to fax_account_fax_document_path(@fax_document.fax_account, @fax_document), :notice => t('fax_documents.controller.successfuly_created')
    else
      render :new
    end
  end

  def destroy
    @fax_account = FaxAccount.find(params[:fax_account_id])
    @fax_document = @fax_account.fax_documents.find(params[:id])
    @fax_document.destroy
    redirect_to fax_account_fax_documents_url, :notice => t('fax_documents.controller.successfuly_destroyed')
  end
  
  private
  def spread_breadcrumbs
    breadcrumbs = []
    breadcrumbs = case @fax_account.fax_accountable.class.to_s
      when 'User'      ; [
                           [@fax_account.fax_accountable.to_s, user_path(@fax_account.fax_accountable)], 
                           [t('fax_accounts.name').pluralize, user_fax_accounts_path(@fax_account.fax_accountable)],
                           [t('fax_documents.name').pluralize, fax_account_fax_documents_path(@fax_account)],
                         ]
      when 'UserGroup' ; [
                           [@fax_account.fax_accountable, user_group_path(@fax_account.fax_accountable)], 
                           [t('fax_accounts.name').pluralize, user_group_fax_accounts_path(@fax_account.fax_accountable)],
                           [t('fax_documents.name').pluralize, fax_account_fax_documents_path(@fax_account)],
                         ]
    end
    if !breadcrumbs.blank?
      breadcrumbs.each do |breadcrumb|
        add_breadcrumb breadcrumb[0], breadcrumb[1]
      end
    end
  end
  
end
