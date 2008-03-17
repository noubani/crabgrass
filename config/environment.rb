
# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.2.3'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')


########################################################################
### BEGIN CUSTOM OPTIONS

SITE_NAME = 'riseup.net'
SECTION_SIZE = 29 # the default size for pagination sections

AVAILABLE_PAGE_CLASSES = %w[
  Message Discussion TextDoc RateMany RankedVote TaskList Asset Event
]

### END CUSTOM OPTIONS
########################################################################


#### ENUMERATIONS ##############

# levels of page access
ACCESS = {
 :admin => 1,
 :change => 2,
 :edit => 2, 
 :view => 3,
 :read => 3
}.freeze

# types of page flows
FLOW = {
 :membership => 1,
 :contacts => 2,
}.freeze

# do this early because environments/*.rb need it
require 'crabgrass_config'

Rails::Initializer.run do |config|
  config.load_paths += %w(associations discussion chat).collect do |dir|
    "#{RAILS_ROOT}/app/models/#{dir}"
  end
  
  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

#  config.action_controller.session_store = :p_store
  
  # Make Active Record use UTC-base instead of local time
  config.active_record.default_timezone = :utc
  
  # See Rails::Configuration for more options
end



#### SESSION HANDLING ##############

#ActionController::Base.session_options[:session_expires] = 3.hours.from_now
#if File.directory? '/dev/shm/'
#  ActionController::Base.session_options[:tmpdir] = '/dev/shm/'
#end
  
#### CUSTOM EXCEPTIONS #############

class PermissionDenied < Exception; end    # the user does not have permission to do that.
class ErrorMessage < Exception; end        # just show a message to the user.
class AssociationError < Exception; end    # thrown when an activerecord has made a bad association (for example, duplicate associations to the same object).

#### CORE LIBRARIES ################

require "#{RAILS_ROOT}/lib/extends_to_core.rb"
require "#{RAILS_ROOT}/lib/extends_to_active_record.rb"
require "#{RAILS_ROOT}/lib/extends_like_edge.rb"
require "#{RAILS_ROOT}/lib/greencloth/greencloth.rb"
require "#{RAILS_ROOT}/lib/misc.rb"
require "#{RAILS_ROOT}/lib/path_finder.rb"

#### TOOLS #########################

# pre-load the tools:
Dir.glob("#{RAILS_ROOT}/app/models/tool/*.rb").each do |toolfile|
  require toolfile
end
# a static array of tool classes:
TOOLS = Tool.constants.collect{|tool|Tool.const_get(tool)}.freeze

AVAILABLE_PAGE_CLASSES.collect!{|i|Tool.const_get(i)}.freeze

#### ASSETS ########################

#Asset.file_storage = "/crypt/files"

# force a new css and javascript url whenever any of the said
# files have a new mtime. this way, no need to expire
# static cache of css and js.
CSS_VERSION = max_mtime("#{RAILS_ROOT}/public/stylesheets/*.css")
JAVASCRIPT_VERSION = max_mtime("#{RAILS_ROOT}/public/javascripts/*.js")

#### TIME ##########################

ENV['TZ'] = 'UTC' # for Time.now
DEFAULT_TZ = 'Pacific Time (US & Canada)'

# remove this when we upgrade to new rails:
require 'acts_like_date_or_time'

#### USER INTERFACE HELPERS ########

FightTheMelons::Helpers::FormMultipleSelectHelperConfiguration.outer_class = 'plainlist'

SVN_REVISION = (RAILS_ENV != 'test' && r = YAML.load(`svn info`)) ? r['Revision'] : nil

require "#{RAILS_ROOT}/vendor/enhanced_migrations-1.2.0/lib/enhanced_migrations.rb"

require 'tagging_extensions'
# These defaults are used in GeoKit::Mappable.distance_to and in acts_as_mappable
GeoKit::default_units = :miles
GeoKit::default_formula = :sphere

# This is the timeout value in seconds to be used for calls to the geocoder web
# services.  For no timeout at all, comment out the setting.  The timeout unit
# is in seconds. 
GeoKit::Geocoders::timeout = 3

# These settings are used if web service calls must be routed through a proxy.
# These setting can be nil if not needed, otherwise, addr and port must be 
# filled in at a minimum.  If the proxy requires authentication, the username
# and password can be provided as well.
GeoKit::Geocoders::proxy_addr = nil
GeoKit::Geocoders::proxy_port = nil
GeoKit::Geocoders::proxy_user = nil
GeoKit::Geocoders::proxy_pass = nil

# This is your yahoo application key for the Yahoo Geocoder.
# See http://developer.yahoo.com/faq/index.html#appid
# and http://developer.yahoo.com/maps/rest/V1/geocode.html
GeoKit::Geocoders::yahoo = 'REPLACE_WITH_YOUR_YAHOO_KEY'
    
# This is your Google Maps geocoder key. 
# See http://www.google.com/apis/maps/signup.html
# and http://www.google.com/apis/maps/documentation/#Geocoding_Examples
#GeoKit::Geocoders::google = 'REPLACE_WITH_YOUR_GOOGLE_KEY'

# the key given here is appropriate for http://localhost/
#GeoKit::Geocoders::google = 'ABQIAAAATL4sfiJFXUFfYtomrKYcMRT2yXp_ZAY8_ufC3CFXhHIE1NvwkxSgdzNqmW5nuNCkPicJS8sOhHTE4w'

# Here's a key for http://localhost:3000
GeoKit::Geocoders::google = 'ABQIAAAA3HdfrnxFAPWyY-aiJUxmqRTJQa0g3IQ9GZqIMmInSLzwtGDKaBQ0KYLwBEKSM7F9gCevcsIf6WPuIQ'

# This is your username and password for geocoder.us.
# To use the free service, the value can be set to nil or false.  For 
# usage tied to an account, the value should be set to username:password.
# See http://geocoder.us
# and http://geocoder.us/user/signup
GeoKit::Geocoders::geocoder_us = false 

# This is your authorization key for geocoder.ca.
# To use the free service, the value can be set to nil or false.  For 
# usage tied to an account, set the value to the key obtained from
# Geocoder.ca.
# See http://geocoder.ca
# and http://geocoder.ca/?register=1
GeoKit::Geocoders::geocoder_ca = false

# This is the order in which the geocoders are called in a failover scenario
# If you only want to use a single geocoder, put a single symbol in the array.
# Valid symbols are :google, :yahoo, :us, and :ca.
# Be aware that there are Terms of Use restrictions on how you can use the 
# various geocoders.  Make sure you read up on relevant Terms of Use for each
# geocoder you are going to use.
GeoKit::Geocoders::provider_order = [:google,:us]
