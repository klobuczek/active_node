require "codeclimate-test-reporter"
CodeClimate::TestReporter.start
#require 'rubygems'
#require 'bundler/setup'
require 'active_node'
require 'neography'
require 'benchmark'
#require 'matchers'
require 'coveralls'
Coveralls.wear!

# If you want to see more, uncomment the next few lines
# require 'net-http-spy'
# Net::HTTP.http_logger_options = {:body => true}    # just the body
# Net::HTTP.http_logger_options = {:verbose => true} # see everything

Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |f| require f }

def generate_text(length=8)
  chars = 'abcdefghjkmnpqrstuvwxyz'
  key = ''
  length.times { |i| key << chars[rand(chars.length)] }
  key
end

RSpec.configure do |c|
  c.filter_run_excluding :slow => true, :gremlin => true
  c.before(:each) do
    @neo=Neography::Rest.new
    @neo.execute_query("MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r")
  end
end


def json_content_type
  {"Content-Type"=>"application/json"}
end

def error_response(attributes)
  request_uri = double()
  allow(request_uri).to receive(:request_uri).and_return("")

  http_header = double()
  allow(http_header).to receive(:request_uri).and_return(request_uri)

  double(
    http_header: http_header,
    code: attributes[:code],
    body: {
    message:   attributes[:message],
    exception: attributes[:exception],
    stacktrace: attributes[:stacktrace]
  }.reject { |k,v| v.nil? }.to_json
  )
end

