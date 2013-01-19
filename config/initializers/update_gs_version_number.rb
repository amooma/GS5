# The Gemeinschaft version is stored in an environment variable.
# It equals the branch in git.
#
if !ENV['GS_VERSION'].nil? && GsParameter.table_exists? && GsParameter.get('GEMEINSCHAFT_VERSION') != ENV['GS_VERSION']
  version = GsParameter.find_or_create_by_name('GEMEINSCHAFT_VERSION')
  version.section = 'Generic'
  version.value = ENV['GS_VERSION']
  version.save
end
