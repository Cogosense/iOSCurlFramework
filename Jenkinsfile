properties properties: [
    [
        $class: 'BuildDiscarderProperty',
        strategy: [$class: 'LogRotator', artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '30']
    ]
]

node('osx && ios') {
    def contributors = null
    def scmLogWs = 'scmLogs' + env.BUILD_NUMBER
    currentBuild.result = "SUCCESS"

    // clean workspace
    deleteDir()
    sshagent(['38bf8b09-9e52-421a-a8ed-5280fcb921af']) {
	stage 'Checkout Source'
	checkout scm
    }

    try {
	stage name: 'Create Change Logs', concurrency: 1
	ws("workspace/${env.JOB_NAME}/../${scmLogWs}") {
	    sshagent(['38bf8b09-9e52-421a-a8ed-5280fcb921af']) {
		checkout scm

		// Load the SCM util scripts first
		checkout([$class: 'GitSCM',
			    branches: [[name: '*/master']],
			    doGenerateSubmoduleConfigurations: false,
			    extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'utils']],
			    submoduleCfg: [],
			    userRemoteConfigs: [[url: 'git@github.com:Cogosense/JenkinsUtils.git', credentialsId: '38bf8b09-9e52-421a-a8ed-5280fcb921af']]])

		dir('./SCM') {
		    sh '../utils/scmBuildDate > TIMESTAMP'
		    sh '../utils/scmBuildTag > TAG'
		    sh '../utils/scmBuildContributors > CONTRIBUTORS'
		    sh '../utils/scmBuildOnHookEmail > ONHOOK_EMAIL'
		    sh '../utils/scmCreateChangeLogs -o CHANGELOG'
		    sh '../utils/scmTagLastBuild'
		}
	    }
	    stash name: 'curlSCM', includes: 'SCM/**'
	    // remove workspace
	    deleteDir()
	}

	unstash 'curlSCM'
	contributors = readFile './SCM/ONHOOK_EMAIL'

	stage 'Notify Build Started'
	if(contributors && contributors != '') {
	    mail subject: "Jenkins Build Started: (${env.JOB_NAME})",
		    body: "You are on the hook}.\nFor more information: ${env.JOB_URL}",
		    to: contributors,
		    from: 'support@cogosense.com'
	}

	stash name: 'Makefile', includes: 'Makefile'

	stage 'Build Parallel'
	parallel (
	    "arm" : {
		node('osx && ios') {
		    // clean workspace
		    deleteDir()
		    unstash 'Makefile'
		    sh 'make clean'
		    sh 'make arm'
		    stash name: 'arm', includes: '**/arm-apple-darwin/curl.framework/**'
		}
	    },
	    "arm64" : {
		node('osx && ios') {
		    // clean workspace
		    deleteDir()
		    unstash 'Makefile'
		    sh 'make clean'
		    sh 'make arm64'
		    stash name: 'arm64', includes: '**/aarch64-apple-darwin/curl.framework/**'
		}
	    },
	    "x86" : {
		node('osx && ios') {
		    // clean workspace
		    deleteDir()
		    unstash 'Makefile'
		    sh 'make clean'
		    sh 'make x86'
		    stash name: 'x86', includes: '**/i386-apple-darwin/curl.framework/**'
		}
	    },
	    "x86_64" : {
		node('osx && ios') {
		    // clean workspace
		    deleteDir()
		    unstash 'Makefile'
		    sh 'make clean'
		    sh 'make x86_64'
		    stash name: 'x86_64', includes: '**/x86_64-apple-darwin/curl.framework/**'
		}
	    }
	)

	unstash 'arm'
	unstash 'arm64'
	unstash 'x86'
	unstash 'x86_64'

	stage 'Assemble Framework'
	sh 'make framework-no-build'

	stage 'Archive Artifacts'
	// Archive the SCM logs, the framework directory
	step([$class: 'ArtifactArchiver',
		artifacts: 'SCM/**, curl.framework/**',
		fingerprint: true,
		onlyIfSuccessful: true])

    } catch(err) {
	currentBuild.result = "FAILURE"
	mail subject: "Jenkins Build Failed: (${env.JOB_NAME})",
		body: "Project build error ${err}.\nFor more information: ${env.BUILD_URL}",
		to: contributors ? contributors : '',
		bcc: 'swilliams@cogosense.com',
		from: 'support@cogosense.com'
	throw err
    }

    stage 'Notify Build Completion'
    if(contributors && contributors != '') {
	mail subject: "Jenkins Build Completed Successfully: (${env.JOB_NAME})",
		body: "You are off the hook}.\nFor more information: ${env.BUILD_URL}",
		to: contributors,
		from: 'support@cogosense.com'
    }
}
