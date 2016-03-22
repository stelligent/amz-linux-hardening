require 'serverspec'

describe file('/opt/aws/inspector/bin/inspector') do
  it { should be_file }
  it { should be_owner 'root' }
  it { should be_executable }
end

describe file('/var/tmp/install') do
  it { should_not be_file }
end
