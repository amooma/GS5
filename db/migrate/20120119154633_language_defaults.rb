# ruby encoding: utf-8

class LanguageDefaults < ActiveRecord::Migration
  def up
	################################################################
	# Languages
	################################################################
	Language.create(:name => 'Deutsch', :code => 'de')
	Language.create(:name => 'English', :code => 'en')
  end

  def down
  	Language.destroy_all
  end
end
