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
      format.tiff {
        caller_number = @fax_document.caller_id_number.to_s.gsub(/[^0-9]/, '')
        if caller_number.blank?
          caller_number = 'anonymous'
        end

        if @fax_document.tiff
          send_file @fax_document.tiff, :type => "image/tiff", 
            :filename => "#{@fax_document.created_at.strftime('%Y%m%d-%H%M%S')}-#{caller_number}.tiff"
        else
          render(
            :status => 404,
            :layout => false,
            :content_type => 'text/plain',
            :text => "<!-- Raw image not found -->",
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
    if @fax_account && @fax_account.fax_accountable.class == User
      add_breadcrumb t("users.index.page_title"), tenant_users_path(@fax_account.fax_accountable.current_tenant)
      add_breadcrumb @fax_account.fax_accountable, tenant_user_path(@fax_account.fax_accountable.current_tenant, @fax_account.fax_accountable)
    end

    if @fax_account
      add_breadcrumb t("fax_accounts.index.page_title"), user_fax_accounts_path(@fax_account.fax_accountable)
      add_breadcrumb @fax_account, user_fax_account_path(@fax_account.fax_accountable, @fax_account)
      if @fax_document && !@fax_document.new_record?
        add_breadcrumb @fax_document, fax_account_fax_document_path(@fax_account, @fax_document)
      end
    end
  end
  
end
