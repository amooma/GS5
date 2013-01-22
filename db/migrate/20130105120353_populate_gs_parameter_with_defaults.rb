class PopulateGsParameterWithDefaults < ActiveRecord::Migration
  def up
    add_column :gs_parameters, :entity, :string, :after => :id
    # Generic
    #
    GsParameter.create(:name => 'GEMEINSCHAFT_VERSION', :section => 'Generic', :value => '5.0.2-nightly-build', :class_type => 'String')
    GsParameter.create(:name => 'SUPER_TENANT_NAME', :section => 'Generic', :value => 'Super-Tenant', :class_type => 'String')

    # System defaults
    #
    GsParameter.create(:name => 'MINIMUM_PIN_LENGTH', :section => 'System defaults', :value => '4', :class_type => 'Integer')
    GsParameter.create(:name => 'MAXIMUM_PIN_LENGTH', :section => 'System defaults', :value => '10', :class_type => 'Integer')

    # GUI
    #
    GsParameter.create(:name => 'GUI_REDIRECT_HTTPS', :section => 'GUI', :value => 'false', :class_type => 'Boolean')

    # Phone numbers
    # Only touch this if you know what you are doing!
    #
    GsParameter.create(:name => 'STRICT_INTERNAL_EXTENSION_HANDLING', :section => 'Phone numbers', :value => 'false', :class_type => 'Boolean')
    GsParameter.create(:name => 'STRICT_DID_HANDLING', :section => 'Phone numbers', :value => 'false', :class_type => 'Boolean')

    # SIP defaults
    #
    GsParameter.create(:name => 'DEFAULT_LENGTH_SIP_AUTH_NAME', :section => 'SIP Defaults', :value => '10', :class_type => 'Integer')
    GsParameter.create(:name => 'DEFAULT_LENGTH_SIP_PASSWORD', :section => 'SIP Defaults', :value => '15', :class_type => 'Integer')
    GsParameter.create(:name => 'CALL_WAITING', :section => 'SIP Defaults', :value => 'false', :class_type => 'Boolean')
    GsParameter.create(:name => 'DEFAULT_CLIR_SETTING', :section => 'SIP Defaults', :value => 'false', :class_type => 'Boolean')
    GsParameter.create(:name => 'DEFAULT_CLIP_SETTING', :section => 'SIP Defaults', :value => 'true', :class_type => 'Boolean')
    GsParameter.create(:name => 'TO_S_MAX_CALLER_NAME_LENGTH', :section => 'SIP Defaults', :value => '25', :class_type => 'Integer')
    GsParameter.create(:name => 'TO_S_MAX_LENGTH_OF_AUTH_NAME', :section => 'SIP Defaults', :value => '6', :class_type => 'Integer')

    # Pagination defaults
    #
    GsParameter.create(:name => 'DEFAULT_PAGINATION_ENTRIES_PER_PAGE', :section => 'Pagination defaults', :value => '50', :class_type => 'Integer')

    # Conference defaults
    #
    GsParameter.create(:name => 'MAXIMUM_NUMBER_OF_PEOPLE_IN_A_CONFERENCE', :section => 'Conference defaults', :value => '100', :class_type => 'Integer')
    GsParameter.create(:name => 'DEFAULT_MAX_CONFERENCE_MEMBERS', :section => 'Conference defaults', :value => '10', :class_type => 'Integer')

    # Misc defaults
    #
    GsParameter.create(:name => 'MAX_EXTENSION_LENGTH', :section => 'Misc defaults', :value => '6', :class_type => 'Integer')

    # Fax defaults
    #
    GsParameter.create(:name => 'DEFAULT_NUMBER_OF_RETRIES', :section => 'Fax defaults', :value => '3', :class_type => 'Integer')
    GsParameter.create(:name => 'DAYS_TILL_AUTO_DELETE', :section => 'Fax defaults', :value => '90', :class_type => 'Integer')

    # Names of PhoneNumberRanges
    #
    GsParameter.create(:name => 'INTERNAL_EXTENSIONS', :section => 'PhoneNumberRanges defaults', :value => 'internal_extensions', :class_type => 'String')
    GsParameter.create(:name => 'SERVICE_NUMBERS', :section => 'PhoneNumberRanges defaults', :value => 'service_numbers', :class_type => 'String')
    GsParameter.create(:name => 'DIRECT_INWARD_DIALING_NUMBERS', :section => 'PhoneNumberRanges defaults', :value => 'direct_inward_dialing_numbers', :class_type => 'String')

    # Callthrough defaults
    #
    GsParameter.create(:name => 'CALLTHROUGH_HAS_WHITELISTS', :section => 'Callthrough defaults', :value => 'true', :class_type => 'Boolean')

    # Huntgroup defaults
    #
    GsParameter.create(:name => 'HUNT_GROUP_STRATEGIES', :section => 'Huntgroup defaults', :value => ['ring_all', 'ring_recursively'].to_yaml, :class_type => 'YAML')
    GsParameter.create(:name => 'VALID_SECONDS_BETWEEN_JUMPS_VALUES', :section => 'Huntgroup defaults', :value => (1 .. 60).to_a.map{|x| x * 2}.to_yaml, :class_type => 'YAML')

    # Callforward defaults
    #
    GsParameter.create(:name => 'DEFAULT_CALL_FORWARD_DEPTH', :section => 'Callforward defaults', :value => '1', :class_type => 'Integer')
    GsParameter.create(:name => 'MAX_CALL_FORWARD_DEPTH', :section => 'Callforward defaults', :value => '40', :class_type => 'Integer')
    GsParameter.create(:name => 'CALLFORWARD_DESTINATION_DEFAULT', :section => 'Callforward defaults', :value => '+49', :class_type => 'String')
    GsParameter.create(:name => 'CALLFORWARD_RULES_ACT_PER_SIP_ACCOUNT_DEFAULT', :section => 'Callforward defaults', :value => 'true', :class_type => 'Boolean')

    # Phone
    #
    GsParameter.create(:name => 'PROVISIONING_AUTO_ADD_PHONE', :section => 'Phone', :value => 'true', :class_type => 'Boolean')
    GsParameter.create(:name => 'PROVISIONING_AUTO_ADD_SIP_ACCOUNT', :section => 'Phone', :value => 'true', :class_type => 'Boolean')
    GsParameter.create(:name => 'PROVISIONING_AUTO_TENANT_ID', :section => 'Phone', :value => '2', :class_type => 'Integer')
    GsParameter.create(:name => 'PROVISIONING_AUTO_SIP_ACCOUNT_CALLER_PREFIX', :section => 'Phone', :value => 'Gemeinschaft ', :class_type => 'String')
    GsParameter.create(:name => 'PROVISIONING_IEEE8021X_EAP_USERNAME', :section => 'Phone', :value => '', :class_type => 'String')
    GsParameter.create(:name => 'PROVISIONING_IEEE8021X_EAP_PASSWORD', :section => 'Phone', :value => '', :class_type => 'String')
    GsParameter.create(:name => 'NIGHTLY_REBOOT_OF_PHONES', :section => 'Phone', :value => 'true', :class_type => 'Boolean')
    GsParameter.create(:name => 'SIEMENS_HISTORY_RELOAD_TIMES', :section => 'Phone', :value => {0..6 => 600, 7..20 => 40, 21..24 => 300}.to_yaml, :class_type => 'YAML')

    # API configuration
    #
    GsParameter.create(:name => 'DEFAULT_API_TENANT_ID', :section => 'API configuration', :value => '2', :class_type => 'Integer')
    GsParameter.create(:name => 'REMOTE_IP_ADDRESS_WHITELIST', :section => 'API configuration', :value => [].to_yaml, :class_type => 'YAML') # e.g. ['10.0.0.1']
    GsParameter.create(:name => 'IMPORT_CSV_FILE', :section => 'API configuration', :value => '/var/tmp/ExampleVoipCsvExport.csv', :class_type => 'String')
    GsParameter.create(:name => 'DOUBLE_CHECK_POSITIVE_USERS_CSV', :section => 'API configuration', :value => '/var/tmp/ExampleDoubleCheckVoipCsvExport.csv', :class_type => 'String')
    GsParameter.create(:name => 'IMPORT_CSV_ENCODING', :section => 'API configuration', :value => 'UTF-8', :class_type => 'String')
    GsParameter.create(:name => 'USER_NAME_PREFIX', :section => 'API configuration', :value => 'dtc', :class_type => 'String')
    GsParameter.create(:name => 'CALLTHROUGH_NAME_TO_BE_USED_FOR_DEFAULT_ACTIVATION', :section => 'API configuration', :value => 'Callthrough for employees', :class_type => 'String')

    # GS Cluster configuration
    #
    GsParameter.create(:name => 'WRITE_GS_CLUSTER_SYNC_LOG', :section => 'GS Cluster ', :value => 'true', :class_type => 'Boolean')
    GsParameter.create(:name => 'HOMEBASE_IP_ADDRESS', :section => 'GS Cluster ', :value => '0.0.0.0', :class_type => 'String')
  end

  def down
    GsParameter.destroy_all
  end
end
