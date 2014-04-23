
if Rails.env.production?
	Paperclip::Attachment.default_options[:storage] = :s3
	Paperclip::Attachment.default_options[:s3_credentials] = {
	  :bucket => ENV['AWS_BUCKET'],
	  :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
	  :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY']
	}
elsif Rails.env.staging?
	# Paperclip::Attachment.default_options[:storage] = :s3
	# Paperclip::Attachment.default_options[:s3_credentials] = {
	#   :bucket => '',
 #    :access_key_id => '',
 #    :secret_access_key => ''
	# }
end