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
        else
          if params[:transfer_attended] && @call.b_sip_account.phones.first.phone_model.manufacturer.name == 'SNOM Technology AG'
            phone = @call.b_sip_account.phones.first
            ip_address = phone.ip_address
            http_user = phone.http_user
            http_password = phone.http_password

            # Hold
            open("http://#{ip_address}/command.htm?key=F_HOLD", :http_basic_authentication=>[http_user, http_password])

            # Call the other party
            (0..(params[:transfer_attended].length - 1)).each do |i|
              digit = params[:transfer_attended][i]
              open("http://#{ip_address}/command.htm?key=#{digit}", :http_basic_authentication=>[http_user, http_password])
            end
            open("http://#{ip_address}/command.htm?key=ENTER", :http_basic_authentication=>[http_user, http_password])
          end
        end

        respond_with @call
      end

    end
  end
end
