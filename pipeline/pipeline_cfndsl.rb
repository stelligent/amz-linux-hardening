CloudFormation {

  S3_Bucket('rArtifactStore') {
    BucketName "centos-pipeline-artefact-store#{Time.now.to_i}"
    VersioningConfiguration({
                              'Status' => 'Enabled'
                            })
  }

  IAM_Role('CodePipelineTrustRole') {
    AssumeRolePolicyDocument JSON.load <<-END
      {
        "Statement":[
          {
            "Sid":"1",
            "Effect":"Allow",
            "Principal":{
              "Service":[
                "codepipeline.amazonaws.com"
              ]
            },
            "Action":"sts:AssumeRole"
          }
        ]
      }
    END

    Path '/'

    Policies JSON.load <<-END
      [
        {
          "PolicyName":"CodePipelinePolicy",
          "PolicyDocument":{
            "Version":"2012-10-17",
            "Statement":[
              {
                "Action":[
                  "s3:GetObject",
                  "s3:GetObjectVersion",
                  "s3:GetBucketVersioning",
                  "s3:PutObject"
                ],
                "Resource": [
                  "arn:aws:s3:::centos-pipeline-artefact-store*"
                 ],
                "Effect":"Allow"
              },
              {
                "Action":[
                  "iam:PassRole"
                ],
                "Resource":"*",
                "Effect":"Allow"
              }
            ]
          }
        }
      ]
    END
  }

  source_artefact_name = 'centosAmiSourceCodeArtefact'
  create_system_image_action_name = 'create-system-image'
  test_system_image_action_name = 'test-system-image'
  system_image_artefact_name = 'systemImageWorkspace'

  [
    {
      logical_resource_id: 'rCreateSystemImageCustomAction',
      category: 'Build',
      provider: create_system_image_action_name
    },
    {
      logical_resource_id: 'rTestSystemImageCustomAction',
      category: 'Test',
      provider: test_system_image_action_name
    }
  ].each do |custom_action|
    Resource(custom_action[:logical_resource_id]) {
      Type 'AWS::CodePipeline::CustomActionType'

      Property 'Category', custom_action[:category]
      Property 'Provider', custom_action[:provider]
      Property 'Version', '1'
      Property 'ConfigurationProperties', [
        {
          'Name' => 'ProjectName',
          'Description' => 'The name of the build project must be provided when this action is added to the pipeline.',
          'Key' => true,
          'Queryable' => false,
          'Required' => true,
          'Secret' => false,
          'Type' => 'String'
        }
      ]

      Property 'InputArtifactDetails', {
        'MaximumCount' => '5',
        'MinimumCount' => '1'
      }

      Property 'OutputArtifactDetails', {
        'MaximumCount' => '5',
        'MinimumCount' => '0'
      }

      Property 'Settings', {
        'EntityUrlTemplate' => FnJoin('', [jenkins_url, 'job/{Config:ProjectName}']),
        'ExecutionUrlTemplate' => FnJoin('', [jenkins_url, 'job/{Config:ProjectName}/{ExternalExecutionId}'])
      }
    }
  end

  Resource('rPipeline') {
    Type 'AWS::CodePipeline::Pipeline'

    Property 'Name', 'centos-hardened-ami'

    Property 'RestartExecutionOnUpdate', false

    Property 'Stages', [
      {
         'Name' => 'source',
         'Actions' => [
           {
             'Name' => 'source',
             'ActionTypeId' => {
                 'Category' => 'Source',
                 'Owner' => 'ThirdParty',
                 'Version' => '1',
                 'Provider' => 'GitHub'
             },
             'OutputArtifacts' => [
               {
                 'Name' => source_artefact_name
               }
             ],
             'Configuration' => {
                 'Owner' => GitHubUser,
                 'Repo' => Repo,
                 'Branch' => Branch,
                 'OAuthToken' => GitHubToken
             }
           }
         ]
      },
      {
         'Name' => 'commit',
         'Actions' => [
           {
             'Name' => 'create-system-image',
             'ActionTypeId' => {
               'Category' => 'Build',
               'Owner' => 'Custom',
               'Version' => '1',
               'Provider' => create_system_image_action_name
             },
             'RunOrder' => 1,
             'InputArtifacts' => [
               {
                 'Name' => source_artefact_name
               }
             ],
             'OutputArtifacts' => [
               {
                 'Name' => system_image_artefact_name
               }
             ],
             'Configuration' => {
               'ProjectName' => create_system_image_action_name
             }
           },
           {
             'Name' => 'test-and-certify-system-image',
             'ActionTypeId' => {
               'Category' => 'Test',
               'Owner' => 'Custom',
               'Version' => '1',
               'Provider' => test_system_image_action_name
             },
             'RunOrder' => 2,
             'InputArtifacts' => [
               {
                 'Name' => system_image_artefact_name
               }
             ],
             'Configuration' => {
               'ProjectName' => test_system_image_action_name
             }
           }
         ]
      }
    ]

    Property 'ArtifactStore', {
                                'Location' => Ref('rArtifactStore'),
                                'Type' => 'S3'
                              }

    Property 'RoleArn', FnGetAtt('CodePipelineTrustRole', 'Arn')
  }

  Output(:codePipelineName,
         Ref('rPipeline'))
}