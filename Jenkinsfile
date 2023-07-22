pipeline {
    
    agent{ label 'jenkins-agent'}

    options {
        buildDiscarder logRotator(artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '3')
        disableConcurrentBuilds()
        timestamps()
    }
    
    environment {
        DOCKER_REGISTRY_USER=credentials('docker-registry-login')
        DOCKER_REGISTRY_PWD=credentials('docker-registry-atr-crm')
        DOCKER_REGISTRY_SITE=credentials('docker-registry-site')
        DOCKER_HOST_TEST = credentials('docker-host')
        DOCKER_HOST_PROD = credentials('docker-host-prod')
        BranchName = "${env.BRANCH_NAME}"
        DockerRegistryURL = 'docker-registry.atr-crm.ru'
        BuildTimestamp = "${BUILD_TIMESTAMP}"
        DOMAIN_DVESTOLICY_PROD = credentials('domain-dvestolicy-ru-prod')
        DOMAIN_DVESTOLICY_TEST = credentials('domain-dvestolicy-ru-test')
    }
    
    stages {
        stage('Checkout SCM') {
            steps {
                script {
                    deleteDir()
                    def scmVars = checkout([
                    $class: 'GitSCM',
                    extensions: [[$class: 'CleanCheckout']],
                    branches: scm.branches,
                    userRemoteConfigs: [[
                        url: 'git@github.com:atr-media/dve-stolicy.ru.git',
                        credentialsId: '76297bd8-f5e6-4060-b1c5-8178210a0519',
                    ]]
                    ])

                    // Display the variable using scmVars
                    echo "scmVars.GIT_COMMIT"
                    echo "${scmVars.GIT_COMMIT}"
                        
                    // Displaying the variables saving it as environment variable
                    env.HashCommit = scmVars.GIT_COMMIT
                    echo "env.HashCommit"
                    echo "${env.HashCommit}"

                    env.GitAuthor = sh(returnStdout: true, script: "git show -s --pretty=%an").trim()
                    echo "env.GitAuthor"
                    echo "${env.GitAuthor}"

                    withCredentials([string(credentialsId: 'BotTelegramSecretToken', variable: 'TOKEN'), string(credentialsId: 'ChatId', variable: 'CHAT_ID')]) {
                    sh("""
                        curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d chat_id="${CHAT_ID}" -d parse_mode="markdown" -d text="
                        \n*Project*: [${JOB_NAME}](${JOB_URL}) \
                        \n*Branch*: [${BranchName}](https://github.com/atr-media/dve-stolicy.ru/tree/${BranchName}) \
                        \n*Build #${BUILD_NUMBER}*: [Starting...](${env.BUILD_URL})"
                    """)
                    }
                }
            }
        }
        stage('Docker Build') {
            steps {
                script {
                    build(BranchName)
                }
            }
        }
        stage('Deploy') {
            steps {
                deploy(BranchName)
            }
        }
    }
        post {
            success {
                withCredentials([string(credentialsId: 'BotTelegramSecretToken', variable: 'TOKEN'), string(credentialsId: 'ChatId', variable: 'CHAT_ID')]) {
                sh("""
                    curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d chat_id="${CHAT_ID}" -d parse_mode="markdown" -d text="
                    \n*Project*: [${JOB_NAME}](${JOB_URL}) \
                    \n*Branch*: [${BranchName}](https://github.com/atr-media/dve-stolicy.ru/tree/${BranchName}) \
                    \n*Build #${BUILD_NUMBER}*: [SUCCESS](${env.BUILD_URL}), [console](${env.BUILD_URL}console) \
                    \n*Commit Author*: ${GitAuthor} \
                    \n*HashCommit*: [${HashCommit}](https://github.com/atr-media/dve-stolicy.ru/commit/${HashCommit}) \
                    \n*BuildTimestamp*: ${BuildTimestamp} \
                    \n*Site URL*: ${DomainSite}"
                """)
                }
             }
            aborted {
                withCredentials([string(credentialsId: 'BotTelegramSecretToken', variable: 'TOKEN'), string(credentialsId: 'ChatId', variable: 'CHAT_ID')]) {
                sh("""
                    curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d chat_id="${CHAT_ID}" -d parse_mode="markdown" -d text="
                    \n*Project*: [${JOB_NAME}](${JOB_URL}) \
                    \n*Branch*: [${BranchName}](https://github.com/atr-media/dve-stolicy.ru/tree/${BranchName}) \
                    \n*Build #${BUILD_NUMBER}*: _ABORTED_, ${env.BUILD_URL}, [console](${env.BUILD_URL}console) \
                    \n*Commit Author*: ${GitAuthor} \
                    \n*HashCommit*: [${HashCommit}](https://github.com/atr-media/dve-stolicy.ru/commit/${HashCommit}) \
                    \n*BuildTimestamp*: ${BuildTimestamp} \
                    \n*Site URL*: ${DomainSite}"
                """)
                }
            }
            failure {
                withCredentials([string(credentialsId: 'BotTelegramSecretToken', variable: 'TOKEN'), string(credentialsId: 'ChatId', variable: 'CHAT_ID')]) {
                sh  ("""
                    curl -s -X POST https://api.telegram.org/bot${TOKEN}/sendMessage -d chat_id="${CHAT_ID}" -d parse_mode="markdown" -d text="
                    \n*Project*: [${JOB_NAME}](${JOB_URL}) \
                    \n*Branch*: [${BranchName}](https://github.com/atr-media/dve-stolicy.ru/tree/${BranchName}) \
                    \n*Build #${BUILD_NUMBER}*: _FAILURE_, ${env.BUILD_URL}, [console](${env.BUILD_URL}console) \
                    \n*Commit Author*: ${GitAuthor} \
                    \n*HashCommit*: [${HashCommit}](https://github.com/atr-media/dve-stolicy.ru/commit/${HashCommit}) \
                    \n*BuildTimestamp*: ${BuildTimestamp} \
                    \n*Site URL*: ${DomainSite}"
                """)
                }
            }
       }
}
def build(BranchName) {
    if (BranchName == 'master') {
        env.DOMAIN = "${DOMAIN_DVESTOLICY_PROD}"
    }
    else {
        env.DOMAIN = "${DOMAIN_DVESTOLICY_TEST}"
    }
    sh "chmod +x -R ${env.WORKSPACE}"
    sh 'bash ./build.sh'
    env.DomainSite = "${DOMAIN}"
    echo "${env.DomainSite}"
}
def deploy(BranchName) {
    if (BranchName == 'master') {
        env.DOCKER_SWARM_HOST = "${DOCKER_HOST_PROD}"
    }
    else {
        env.DOCKER_SWARM_HOST = "${DOCKER_HOST_TEST}"
    }
    sh "chmod +x -R ${env.WORKSPACE}"
    sh 'bash ./deploy.sh'
}