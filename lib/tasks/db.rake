# lib/tasks/db.rake
namespace :db do

  #desc "Dumps the database to db/APP_NAME.dump"
  #task :dump => :environment do
  #  cmd = nil
  #  with_config do |app, host, db, user|
  #    cmd = "pg_dump --host #{host} --username #{user} --verbose --clean --no-owner --no-acl --format=c #{db} > #{Rails.root}/db/#{app}.dump"
  #  end
  #  puts cmd
  #  exec cmd
  #end

  desc "Loads the database dump at db/dev_db.sql.gz"
  task :load_dev => :environment do
    cmd = nil
    with_config do |app, host, db, user|
      cmd = "gunzip -c #{Rails.root}/db/dev_db.sql.gz | pg_restore --clean --no-acl --no-owner -h #{host} -U #{user} -d #{db}"
    end
    Rake::Task["db:drop"].invoke
    #Rake::Task["db:create"].invoke
    #Rake::Task["db:migrate"].invoke
    puts cmd
    exec cmd
  end

  private

  def with_config
    yield Rails.application.class.parent_name.underscore,
      ActiveRecord::Base.connection_config[:host],
      ActiveRecord::Base.connection_config[:database],
      ActiveRecord::Base.connection_config[:username]
  end

end
