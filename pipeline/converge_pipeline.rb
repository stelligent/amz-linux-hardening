#!/usr/bin/env ruby
require 'yaml'
require 'cfndsl_converger'

tier = ARGV[0]

def seed_jobs(tier_properties)
  require 'jenkins_api_client'

  client = JenkinsApi::Client.new server_url: tier_properties['server_url'],
                                  username: tier_properties['jenkins_user'],
                                  password: tier_properties['jenkins_pass']

  client.job.create('job-seed',
                    IO.read(File.join('pipeline', 'jobs', 'job-seed-config.xml')))

  client.job.build 'job-seed'
end

def load_properties(tier)
  tier_properties = YAML.load_file(File.join('pipeline', 'tier', "#{tier}.yml"))
  secret_tier_properties = YAML.load_file(File.join('pipeline', 'tier', "#{tier}_secret.yml"))
  tier_properties.merge! secret_tier_properties
end

tier_properties = load_properties tier

converger = CfndslConverger.new
outputs = converger.converge stack_name: "CentOS-Hardened-AMI-Jenkins-Worker-#{tier.upcase}",
                             path_to_stack: 'pipeline/cfndsl/jenkins_cfndsl.rb',
                             bindings: tier_properties

tier_properties['server_url'] = outputs['JenkinsURL']

seed_jobs tier_properties

outputs = converger.converge stack_name: "CentOS-Hardened-AMI-Pipeline-#{tier.upcase}",
                             path_to_stack: 'pipeline/cfndsl/pipeline_cfndsl.rb',
                             bindings: tier_properties

puts "Created CodePipeline pipeline: #{outputs['codePipelineName']}"