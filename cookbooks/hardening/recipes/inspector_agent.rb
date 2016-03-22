remote_file '/var/tmp/install' do
  source 'https://s3-us-west-2.amazonaws.com/inspector.agent.us-west-2/latest/install'
  mode 0700
  action :create
end

bash 'install inspector' do
  cwd '/var/tmp'
  code <<-END
    ./install
  END
end

file '/var/tmp/install' do
  action :delete
end