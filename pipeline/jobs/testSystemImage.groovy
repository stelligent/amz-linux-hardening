job('test-system-image') {
  triggers {
    scm("* * * * *")
  }

  configure { project ->
    project.remove(project / scm) // remove the existing 'scm' element

    project / scm(class: 'com.amazonaws.codepipeline.jenkinsplugin.AWSCodePipelineSCM', plugin: 'codepipeline@0.8') {
      clearWorkspace true
      actionTypeCategory 'Build'
      actionTypeProvider 'JenkinsJPSTUE564bc1e4'
      projectName 'test-system-image'
      actionTypeVersion 1
      region 'us-west-2'
    }

    project.remove(project / publishers)

    project / publishers / 'com.amazonaws.codepipeline.jenkinsplugin.AWSCodePipelinePublisher'(plugin:'codepipeline@0.8') {
      buildOutputs {
        'com.amazonaws.codepipeline.jenkinsplugin.AWSCodePipelinePublisher_-OutputTuple' {
          outputString ''
        }
      }
    }
  }
}