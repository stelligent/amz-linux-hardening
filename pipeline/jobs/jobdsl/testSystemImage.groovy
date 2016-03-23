jobName = 'test-system-image'
awsRegion = 'us-west-2'
customActionTypeVersion = 6

job(jobName) {
  triggers {
    scm('* * * * *')
  }

  steps {
    shell(readFileFromWorkspace("pipeline/jobs/bash/${jobName}.sh"))
  }

  configure { project ->
    project.remove(project / scm) // remove the existing 'scm' element

    project / scm(class: 'com.amazonaws.codepipeline.jenkinsplugin.AWSCodePipelineSCM', plugin: 'codepipeline@0.8') {
      clearWorkspace true
      actionTypeCategory 'Test'
      actionTypeProvider jobName
      projectName jobName
      actionTypeVersion customActionTypeVersion
      region awsRegion

      //this rubbish is apparently necessary, even with instance profiles
      awsAccessKey ''
      awsSecretKey ''
      proxyHost ''
      proxyPort '0'
      awsClientFactory ''
    }

    project.remove(project / publishers)
  }

  wrappers {
    rvm('2.2.1@system-image')
  }
}