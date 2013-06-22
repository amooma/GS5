module Api
  module V1
    class CallsController < ApplicationController
      respond_to :json

      def index
        @calls = Call.limit(10)

        respond_with @calls
      end

      def show
        @call = Call.find(params[:id])

        if params[:transfer_blind]
          @call.transfer_blind(params[:transfer_blind])
        end

        respond_with @call
      end

    end
  end
end
