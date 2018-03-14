require 'net/http'
require 'json'

module BeyondZ
  class Mailchimp
    attr_reader :email
    
    HOST = "https://us11.api.mailchimp.com"
    VERSION = '3.0'
    
    def initialize(email)
      @key = Rails.application.secrets.mailchimp_key
      @list_id = Rails.application.secrets.mailchimp_list_id

      @email = email
    end
    
    def update(new_email)
      return false unless exists?
      
      subscriber_id = search['exact_matches']['members'].first['id']
      
      uri = URI("#{HOST}/#{VERSION}/lists/#{@list_id}/members/#{subscriber_id}")
      
      request = Net::HTTP::Patch.new(uri)
      request.basic_auth 'key', @key
      request.body = {email_address: new_email}.to_json
      
      response = http.request request
      
      json = JSON.parse(response.body)
      json['email_address'] == new_email
    rescue
      false
    end
    
    private
    
    def exists?
      search['exact_matches']['total_items'].to_i > 0
    rescue
      false
    end
    
    def search
      return @search if defined?(@search)
      
      uri = URI("#{HOST}/#{VERSION}/search-members?query=#{email}&list_id=#{@list_id}")

      request = Net::HTTP::Get.new uri
      request.basic_auth 'key', @key
      
      response = http.request request

      @search = JSON.parse(response.body)
    end
    
    def http
      return @http if defined?(@http)
      
      uri = URI(HOST)

      @http = Net::HTTP.new(uri.host, uri.port)
      @http.use_ssl = true
      
      @http
    end
  end
end