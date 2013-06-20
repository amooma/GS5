module Api
  module V1
    class PagerGroupsController < ApplicationController
      skip_before_filter :verify_authenticity_token
      respond_to :json

      def index
        @pager_groups = PagerGroup.all
        respond_with @pager_groups
      end

      def show
        @pager_group = PagerGroup.find(params[:id])
        respond_with @pager_group
      end 

      def new
        if params[:sip_account_id] && SipAccount.find(params[:sip_account_id])
          @pager_group = SipAccount.find(params[:sip_account_id]).pager_groups.new
          @pager_group.callback_url = params[:callback_url]
          @pager_group.pager_group_destination_ids = params[:pager_group_destination_ids]
          if @pager_group.save
            respond_with @pager_group
          end
        end

      end

      def destroy
        @pager_group = PagerGroup.find(params[:id])
        if @pager_group
          @pager_group.destroy
          respond_with @pager_group
        end
      end      

    end
  end
end
