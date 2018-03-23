require 'net/http'
require 'json'

module BeyondZ
  class Mailchimp
    attr_reader :user, :key, :list_id
    
    HOST = "https://us11.api.mailchimp.com"
    VERSION = '3.0'
    
    def initialize(user)
      @user = user
      
      @key = Rails.application.secrets.mailchimp_key
      @list_id = Rails.application.secrets.mailchimp_list_id
    end
    
    def update
      return false unless mailchimp_record
      
      uri = URI("#{HOST}/#{VERSION}/lists/#{@list_id}/members/#{mailchimp_id}")
      
      update_fields = {
        email_address: user.email,
        merge_fields: {
          FNAME: user.first_name,
          LNAME: user.last_name
        }
      }
      
      request = Net::HTTP::Patch.new(uri)
      request.basic_auth 'key', @key
      request.body = update_fields.to_json
      
      response = http.request request
      
      json = JSON.parse(response.body)
      
      # success is based on this boolean test
      json['email_address'] == user.email
    end
    
    def mailchimp_record
      return @mailchimp_record if defined?(@mailchimp_record)
      
      @mailchimp_record = nil
      
      # if we have the mailchimp id, use it directly (best option)
      if user.mailchimp_id
        @mailchimp_record = record_via_mailchimp_id
      end
      
      # if mailchimp_id is unknown or fails, try e-mail BEFORE it was changed
      if @mailchimp_record.nil? && user.changed_attributes.has_key?('email')
        @mailchimp_record = record_via_email(user.changed_attributes['email'])
        save_mailchimp_id if @mailchimp_record
      end
      
      # otherwise, try current e-mail
      if @mailchimp_record.nil?
        @mailchimp_record = record_via_email(user.email)
        save_mailchimp_id if @mailchimp_record
      end
      
      @mailchimp_record
    end
    
    private
    
    def save_mailchimp_id
      user.update mailchimp_id: mailchimp_id
    end
    
    def record_via_email(email)
      uri = URI("#{HOST}/#{VERSION}/search-members?query=#{email}&list_id=#{list_id}")
      record = get(uri)
      
      return nil unless record['exact_matches']['total_items'].to_i > 0
      
      record['exact_matches']['members'].first
    end
    
    def record_via_mailchimp_id
      uri = URI("#{HOST}/#{VERSION}/lists/#{list_id}/members/#{user.mailchimp_id}")
      record = get(uri)
      
      record.has_key?('id') ? record : nil
    end
    
    def get uri
      request = Net::HTTP::Get.new uri
      request.basic_auth 'key', key
      
      response = http.request request
      record = JSON.parse(response.body)
    end
    
    def mailchimp_id
      mailchimp_record ? mailchimp_record['id'] : nil
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