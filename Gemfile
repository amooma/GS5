if RUBY_VERSION =~ /1.9/
  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8
end

source 'http://rubygems.org'

gem 'rails', '3.2.13'
gem 'bcrypt-ruby'
gem 'sqlite3'
gem 'mysql2'
gem 'cancan', '1.6.7'
gem 'state_machine'
gem 'acts_as_list'
gem 'dalli' # memcached
gem 'inifile'
gem 'active_model_serializers' # JSON

# Useful Rails 4 stuff
#
gem 'strong_parameters'
gem 'cache_digests'

# Nicer console output:
gem "hirb"

gem "nokogiri"

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'compass-rails'
  gem 'uglifier', '>= 1.3.0'
end

gem 'json'

gem 'jquery-rails'

group :development do
  gem 'factory_girl_rails'
  gem 'factory_girl'
  gem 'sextant' # Rails 4 stuff
  gem 'quiet_assets' # turns off assets logging

  # Debugging http://railscasts.com/episodes/402-better-errors-railspanel
  gem 'better_errors'
  gem 'binding_of_caller'

  gem 'rails-erd'
end

group :test do
  gem 'factory_girl_rails'
end

gem 'haml'
gem 'simple_form', '~> 2.1.0'

# Image Upload
gem 'carrierwave'
gem "mini_magick"

# Pagination https://github.com/mislav/will_paginate/wiki/Installation
gem 'will_paginate'

# Pagination for Twitter bootstrap
gem 'will_paginate-bootstrap'

# DelayedJob https://github.com/collectiveidea/delayed_job
gem 'daemons'
gem 'delayed_job_active_record'

# https://github.com/iain/http_accept_language
gem 'http_accept_language'

# https://github.com/weppos/breadcrumbs_on_rails
gem 'breadcrumbs_on_rails'

# UUID Generator https://github.com/assaf/uuid
gem 'uuid'

# Application server
gem 'unicorn'

# http://railscasts.com/episodes/316-private-pub
gem 'thin'
gem 'private_pub'

# Backup https://github.com/meskyanichi/backup
gem 'backup'

# Cronjobs
gem 'whenever'

gem 'whois'

# Local Variables:
# mode: ruby
# End:
