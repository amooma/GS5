# The Gemeinschaft version is stored in an environment variable.
# It equals the branch in git.
#
if !ENV['GS_VERSION'].nil? && GsParameter.table_exists? && GsParameter.get('GEMEINSCHAFT_VERSION') != ENV['GS_VERSION']
  if GsParameter.where(:name => 'GEMEINSCHAFT_VERSION').any?
    GsParameter.where(:name => 'GEMEINSCHAFT_VERSION').first.update_attributes(:name => ENV['GS_VERSION'])
  end
end
