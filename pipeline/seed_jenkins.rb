#!/usr/bin/env ruby
require 'jenkins_api_client'

tier = ARGV[0]
server_url = ARGV[1]

credentials = YAML.load_file(File.join('pipeline', 'tier', "#{tier}.yml"))

puts credentials

client = JenkinsApi::Client.new server_url: server_url,
                                username: credentials['jenkins_user'],
                                password: credentials['jenkins_pass']

client.job.create('job-seed',
                  IO.read(File.join('pipeline', 'jobs', 'job-seed-config.xml')))

client.job.build 'job-seed'