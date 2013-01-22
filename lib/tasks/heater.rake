namespace :heater do
  desc "Warm up the cache."
  task :preheat => :environment do
    if GemeinschaftSetup.any?

    else
      # This is a fresh installation.
      #
      if Rails.env.production?
        require 'open-uri'
        open('/dev/null', 'wb') do |file|
          file << open("http://localhost/gemeinschaft_setups/new").read
        end
      end
    end
  end
end