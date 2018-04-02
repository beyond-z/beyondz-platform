require 'net/http'
require 'json'
require 'digest/md5'

module BeyondZ
  module Mailchimp
    class User
      attr_reader :user, :key, :list_id
    
      HOST = "https://us11.api.mailchimp.com"
      VERSION = '3.0'
      UPDATEABLE_FIELDS = ['email', 'first_name', 'last_name', 'bz_region', 'salesforce_id']
    
      def initialize(user)
        @user = user
      
        @key = Rails.application.secrets.mailchimp_key
        @list_id = Rails.application.secrets.mailchimp_list_id
      end
    
      def create
        if mailchimp_record
          error "Mailchimp e-mail record for '#{mailchimp_record['email_address']}' already exists"
          return false
        end
      
        uri = URI("#{HOST}/#{VERSION}/lists/#{@list_id}/members")
        request = Net::HTTP::Post.new(uri)

        change_request :create, request
      end
    
      def update
        unless mailchimp_record
          error("Mailchimp e-mail record was not found")
          return false
        end

        uri = URI("#{HOST}/#{VERSION}/lists/#{@list_id}/members/#{mailchimp_id}")
        request = Net::HTTP::Patch.new(uri)
      
        change_request :update, request
      end
    
      def mailchimp_record
        return @mailchimp_record if defined?(@mailchimp_record)
      
        @mailchimp_record = nil
      
        # Use e-mail BEFORE it was changed, if available
        if user.changed_attributes.has_key?('email')
          @mailchimp_record = record_via_email(user.changed_attributes['email'])
        end
      
        # if pre-changed e-mail doesn't exist, or can't be found on mailchimp, try current e-mail
        if @mailchimp_record.nil?
          @mailchimp_record = record_via_email(user.email)
        end
      
        @mailchimp_record
      end
    
      private
    
      def change_request request_type, request
        fields = {
          status: 'subscribed',
          email_address: user.email,
          merge_fields: {
            FNAME: user.first_name,
            LNAME: user.last_name,
            REGION: user.bz_region,
            SFID: user.salesforce_id
          }
        }
      
        request.basic_auth 'key', @key
        request.body = fields.to_json
      
        response = http.request request
      
        begin
          json = JSON.parse(response.body)
        rescue
          error("Mailchimp JSON Response could not be parsed", response)
        end
      
        # success is based on this boolean test
        success_status = json['email_address'] == user.email
      
        # provide more detail if update fails
        if success_status
          @mailchimp_record = json
        else
          error("Mailchimp #{request_type} was not successful", response)
        end
      
        success_status
      end
    
      def error message, response=nil
        if response && response.methods.include?(:body)
          message += ":\n----\n#{response.body}\n----"
        end
      
        Rails.logger.error(message)
      end

      def hex_digest(email=nil)
        Digest::MD5.hexdigest(email || user.email)
      end
    
      def http
        return @http if defined?(@http)
      
        uri = URI(HOST)

        @http = Net::HTTP.new(uri.host, uri.port)
        @http.use_ssl = true
      
        @http
      end
    
      def mailchimp_id
        mailchimp_record ? mailchimp_record['id'] : nil
      end
    
      def record_via_email(email)
        uri = URI("#{HOST}/#{VERSION}/lists/#{list_id}/members/#{hex_digest(email)}")

        request = Net::HTTP::Get.new uri
        request.basic_auth 'key', key
      
        response = http.request request
        record = JSON.parse(response.body)
      
        record.has_key?('id') ? record : nil
      end

      def requires_update?
        !(user.changed_attributes.keys & UPDATEABLE_FIELDS).empty?
      end
    end
  end
end