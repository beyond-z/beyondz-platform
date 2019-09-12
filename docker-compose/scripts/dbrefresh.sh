#!/bin/bash
echo "Refreshing your local dev database from the staging db"

dbfilename='join_dev_db_dump_latest.sql.gz'
dbfilepathgz="/tmp/$dbfilename"

aws s3 --region us-west-1 cp "s3://join-dev-db-dumps/$dbfilename" $dbfilepathgz
if [ $? -ne 0 ]
then
 echo "Failed downloading s3://join-dev-db-dumps/$dbfilename"
 echo "Make sure that awscli is installed: pip3 install awscli"
 echo "Also, make sure and run 'aws configure' and put in your Access Key and Secret."
 echo "Lastly, make sure your IAM account is in the Developers group. That's where the policy to access this bucket is defined."
 exit 1;
fi


# TODO: ACTUALLY, with heroku we can just directly pull, restore and then run DB commands instead of using the
# staging dump stored on S3. This is much more scalable as teh DB gets bigger than using SED on teh Admin server to adust stuff.
# See https://devcenter.heroku.com/articles/heroku-postgres-import-export

gunzip < $dbfilepathgz | docker-compose exec -T joinweb pg_restore --verbose --clean --no-acl --no-owner -h joindb -U postgres -d joindb

# TODO: this fails b/c there are ignored errors in pg_restore. Need to get to bottom of that, but it generally seems to work even if we ignore them.
#if [ $? -ne 0 ]
#then
#   echo "Error: failed loading the dev database into the dev db. File we tried to load: $dbfilepathgz"
#   exit 1;
#fi

# This is our normal test password for everyone. I got this by loading a dev db with the security keys 
# and stuff we use, then setting someones password to the test one in the rails console.
ENCRYPTED_TEST_PASS='$2a$10$C2W0hszrbmpk8tkw0ViLFOXVFH1Sj6HAiMyGah6vdEoRUj7GK1KzO'
echo "update users set encrypted_password = '$ENCRYPTED_TEST_PASS';" | docker-compose exec -T joindb psql -U postgres joindb

rm $dbfilepathgz
