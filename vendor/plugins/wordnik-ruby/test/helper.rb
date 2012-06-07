require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'fakeweb'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'wordnik-ruby'

class Test::Unit::TestCase
end

FakeWeb.allow_net_connect = false

def fixture_file(filename)
  return "" if filename == ""
  file_path = File.expand_path(File.dirname(__FILE__) + "/fixtures/" + filename)
  return File.read(file_path)
end

def wordnik_url(url)
  url =~ /^http/ ? url : "http://api.wordnik.com/api#{url}"
end

def stub_get(url, filename, status=nil)
  options = {:body => fixture_file(filename)}
  options.merge!(Wordnik.client.api_headers)
  options.merge!({:status => status}) unless status.nil?
  FakeWeb.register_uri(:get, wordnik_url(url), options)
end

def stub_post(url, filename)
  options = {:body => fixture_file(filename)}
  options.merge!(Wordnik.client.api_headers)
  FakeWeb.register_uri(:post, wordnik_url(url), options)
end

def stub_put(url, filename)
  options = {:body => fixture_file(filename)}
  options.merge!(Wordnik.client.api_headers)
  FakeWeb.register_uri(:put, wordnik_url(url), options)
end

def stub_delete(url, filename)
  options = {:body => fixture_file(filename)}
  options.merge!(Wordnik.client.api_headers)
  FakeWeb.register_uri(:delete, wordnik_url(url), options)
end
