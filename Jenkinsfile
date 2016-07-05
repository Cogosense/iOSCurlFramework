properties properties: [
    [
        $class: 'BuildDiscarderProperty',
        strategy: [$class: 'LogRotator', artifactDaysToKeepStr: '', artifactNumToKeepStr: '', daysToKeepStr: '', numToKeepStr: '30']
    ]
]

node('osx && ios') {
    def contributors = null
    currentBuild.result = "SUCCESS"

    // start with a clean workspace
    deleteDir()

    sshagent(['38bf8b09-9e52-421a-a8ed-5280fcb921af']) {

	try {
	    stage name: 'Create Change Logs', concurrency: 1
	    ws("workspace/${env.JOB_NAME}/../scmLogs") {

		checkout scm: [$class: 'GitSCM', clean: true, creadentialsId: '38bf8b09-9e52-421a-a8ed-5280fcb921af']

		// Load the SCM util scripts first
		checkout([$class: 'GitSCM',
			    branches: [[name: '*/master']],
			    doGenerateSubmoduleConfigurations: false,
			    extensions: [[$class: 'RelativeTargetDirectory', relativeTargetDir: 'utils']],
			    submoduleCfg: [],
			    userRemoteConfigs: [[url: 'git@github.com:Cogosense/JenkinsUtils.git', credentialsId: '38bf8b09-9e52-421a-a8ed-5280fcb921af']]])

		sh 'date | tr -d "\n" > SCM_TIMESTAMP'
		sh 'echo -n $BUILD_TAG > SCM_TAG'
		sh 'utils/scmBuildContributors > SCM_CONTRIBUTORS'
		sh 'utils/scmBuildOnHookEmail > SCM_ONHOOK_EMAIL'
		sh 'utils/scmCreateChangeLogs -o SCM_CHANGELOG'
		sh 'utils/scmTagLastBuild'
		stash name: "scmLogs", includes: 'SCM_*'
	    }

	    unstash "scmLogs"
	    contributors = readFile 'SCM_ONHOOK_EMAIL'

	    stage 'Notify Build Started'
	    if(contributors && contributors != '') {
		mail subject: "Jenkins Build Started: (${env.JOB_NAME})",
			body: "You are on the hook}.\nFor more information: ${env.JOB_URL}",
			to: contributors,
			from: 'support@cogosense.com'
	    }

	    stage 'Checkout Source'
	    checkout scm
	    stage 'Clean Workspace'
	    sh 'make clean'
	    stage 'Build'
	    sh 'make'

	    stage 'Archive Artifacts'
	    // Archive the SCM logs, the framework directory
	    step([$class: 'ArtifactArchiver',
		    artifacts: 'SCM_*, curl.framework/**',
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
}

