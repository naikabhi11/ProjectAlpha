pipeline {
    agent any

    environment {
        PATH = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin"
    }

    stages {

        stage('Check Tools Installed') {
            steps {
                sh 'echo Jenkins is working'
                sh 'aws --version'
                sh 'terraform version'
                sh 'packer version'
                sh 'ansible --version'
            }
        }

        stage('Validate AWS Access') {
            steps {
                sh 'aws sts get-caller-identity'
            }
        }

        stage('Validate Terraform') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform validate'
                    sh 'terraform plan'
                }
            }
        }

        stage('Validate Packer') {
            steps {
                dir('packer-demo') {
                    sh 'packer init .'
                    sh 'packer validate .'
                }
            }
        }

        stage('Validate Ansible') {
            steps {
                dir('ansible') {
                    sh 'ansible-playbook playbook.yml'
                }
            }
        }
    }

    post {
        success {
            echo 'All DevOps tools validated successfully.'
        }
        failure {
            echo 'Validation failed.'
        }
    }
}
