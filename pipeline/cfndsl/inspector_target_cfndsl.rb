CloudFormation {

  EC2_Instance('rInspectorTargetInstance') {
    InstanceType 'm3.medium'
    ImageId image_id
    SubnetId subnet_id

    Tags [
      {
        'Key' => 'target',
        'Value' => 'inspector-amz-2015.09.02'
      }
    ]
  }
}