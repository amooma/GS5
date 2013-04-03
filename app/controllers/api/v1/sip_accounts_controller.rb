module Api
  module V1
    class SipAccountsController < ApplicationController
      respond_to :json

      def index
        if params[:ids]
          @sip_accounts = SipAccount.where(:id => params[:ids])
        else
          @sip_accounts = SipAccount.all
        end

        respond_with @sip_accounts
      end

      def show
        @sip_account = SipAccount.find(params[:id])

        respond_with @sip_account
      end  
    end
  end
end
