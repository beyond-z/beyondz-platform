Paperclip::Attachment.default_options[:storage] = :s3
Paperclip::Attachment.default_options[:s3_credentials] = {
  :bucket => Rails.application.secrets.aws_bucket,
  :access_key_id => Rails.application.secrets.aws_access_key_id,
  :secret_access_key => Rails.application.secrets.aws_secret_access_key
}