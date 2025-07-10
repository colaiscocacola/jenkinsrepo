pipeline {
    agent any

    environment {
        REACT_APP_API_URL = credentials('REACT_APP_API_URL') // credentials ID
        DB_PASSWORD = credentials('DB_PASSWORD')
    }

    stages {
        stage('Build') {
            steps {
                script {
                    writeFile file: '.env', text: """
                    REACT_APP_API_URL=${env.REACT_APP_API_URL}
                    DB_PASSWORD=${env.DB_PASSWORD}
                    """
                }
                sh 'docker build -t react-app .'
            }
        }
    }
}