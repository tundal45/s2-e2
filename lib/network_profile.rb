require 'rubygems'
require 'json'
require 'open-uri'
require 'nokogiri'
require 'digest/md5'
  
class NetworkProfile
  attr_accessor :config, :network, :email, :profile_url
  
  def initialize(param, config)
    @network = param[:network]
    @email = param[:email]
    @config = config
  end
  
  def find
    search
    respond
  end
  
  def respond
    @profile_url.nil? ? "We could not locate a user with #{@email} on #{@network}" : @profile_url
  end
end

class FlickrProfile < NetworkProfile

  def search
    request_url = "#{@config[:api_base_url]}method=#{@config[:email_method]}&api_key=#{@config[:api_key]}&find_email=#{@email}"
    response = Nokogiri::XML(open(request_url))
    
    if response.at_css("rsp").attributes["stat"].value.eql?("ok")
      nsid = response.at_css("user").attributes["nsid"].inner_text
      request_url = "#{@config[:api_base_url]}method=#{@config[:profile_method]}&api_key=#{@config[:api_key]}&user_id=#{nsid}"
      
      response = Nokogiri::XML(open(request_url))
      @profile_url = response.at_css("user").attributes["url"].inner_text
    else
      @profile_url = nil
    end
  end
end

class GitHubProfile < NetworkProfile

  def search
    request_url = "#{@config[:api_base_url]}#{@email}"
    user_name = JSON.parse(open(request_url).read)["user"]["login"]
    @profile_url = "#{@config[:profile_base_url]}#{user_name}"
  rescue OpenURI::HTTPError
    @profile_url = nil
  end
end

class OhLohProfile < NetworkProfile

  def search
    md5 = Digest::MD5.hexdigest(@email)
    request_url = "#{@config[:profile_base_url]}#{md5}"
    response = Nokogiri::HTML(open(request_url))
    user_name = response.at_css("title").children.inner_text.gsub!(/\s-.*/, "")
    @profile_url = "#{@config[:profile_base_url]}#{user_name}"
  rescue Errno::ENOENT
    @profile_url = nil
  end
end
