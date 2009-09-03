require 'rubygems'
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'active_record'
require 'action_controller'
require 'active_record/fixtures'
require 'active_support'
require 'action_pack'
require 'action_view'
require 'rails/init'
require 'action_view/test_case'

require 'google_otg'

class Test::Unit::TestCase
end

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")

ActiveRecord::Schema.define(:version => 1) do
  create_table :hits do |t|
    t.integer :count
    t.datetime :created_at
  end
end

class Hit < ActiveRecord::Base
    validates_presence_of :count
end

(1..3).each{|idx| 
    ca = (3 - idx).hours.ago
    range = GoogleOtg::DEFAULT_RANGE
    ca = Time.at((ca.to_i/(60*range))*(60*range))

    Hit.create(:count => rand(65535), :created_at => ca)
}

