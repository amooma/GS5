class ChangeRfc2833ProfileParameter < ActiveRecord::Migration
  def up
    pass_rfc2833 = GsParameter.where(:entity => 'sofia', :section => 'profile', :name => 'pass-rfc2833').first
    if pass_rfc2833
      pass_rfc2833.update_attributes(:value => 'false')
    end
  end

  def down
    pass_rfc2833 = GsParameter.where(:entity => 'sofia', :section => 'profile', :name => 'pass-rfc2833').first
    if pass_rfc2833
      pass_rfc2833.update_attributes(:value => 'true')
    end
  end
end
