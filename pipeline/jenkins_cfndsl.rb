CloudFormation {

  Mapping 'RegionConfig', {
    'us-east-1' => {
      'ami' => 'ami-e2754888'
    },
    'us-west-2' => {
      'ami' => 'ami-677c9e07'
    }
  }

  EC2_SecurityGroup('JenkinsSecurityGroup') {
    VpcId vpc_id
    GroupDescription 'Will mostly be phoning home to CP'
  }

  %w(22 8080).each do |ingress_port|
    EC2_SecurityGroupIngress("SecurityGroupIngress#{ingress_port}") {
      GroupId Ref('JenkinsSecurityGroup')
      IpProtocol 'tcp'
      FromPort ingress_port.to_s
      ToPort ingress_port.to_s
      CidrIp jenkins_ingress_ssh_cidr
    }
  end

  EC2_Instance('JenkinsInstance') {
    ImageId FnFindInMap('RegionConfig', Ref('AWS::Region'), 'ami')
    InstanceType 'm4.large'
    KeyName jenkins_ec2_key_pair_name

    NetworkInterfaces [
      NetworkInterface {
        GroupSet Ref('JenkinsSecurityGroup')
        AssociatePublicIpAddress 'true'
        DeviceIndex 0
        DeleteOnTermination true
        SubnetId subnet_id
      }
    ]

    UserData FnBase64(FnJoin(
      '',
      [
        "#!/bin/bash -xe\n",
        "yum update -y aws-cfn-bootstrap\n",
        "yum -y upgrade\n",

        "service jenkins start\n",

        '/opt/aws/bin/cfn-signal -e $? ',
        '                        --stack ', Ref('AWS::StackName'),
        '                        --resource JenkinsInstance ',
        '                        --region ',Ref('AWS::Region'),"\n"
      ]
    ))

    CreationPolicy('ResourceSignal', { 'Count' => 1,  'Timeout' => 'PT15M' })
  }

  Output(:JenkinsURL,
         FnJoin('', [ 'http://', FnGetAtt('JenkinsInstance', 'PublicIp'), ':8080/']))
}
