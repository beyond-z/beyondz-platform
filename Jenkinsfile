pipeline {
  agent any
  stages {
    stage('build docker image and tag') {
      steps {
        sh 'sudo docker build -t join .'
      }
    }
    stage('ecr push') {
      steps {
        sh '''eval sudo $(aws ecr get-login --no-include-email --region us-west-2)
latest_tag=$(aws ecr describe-images --repository-name join --region us-west-2  --output text --query \'sort_by(imageDetails,& imagePushedAt)[*].imageTags[*]\' | tr \'\\t\' \'\\n\'  | tail -1)
if [ -z ${latest_tag} ]; then
  VERSION_TAG=1.0.0
else
  VERSION_TAG="${latest_tag%.*}.$((${latest_tag##*.}+1))"
fi
sudo docker tag portal 958491237157.dkr.ecr.us-west-2.amazonaws.com/join:${VERSION_TAG}
sudo docker push 958491237157.dkr.ecr.us-west-2.amazonaws.com/join:${VERSION_TAG}'''
      }
    }
  }
  triggers {
    pollSCM('* * * * *')
  }
}