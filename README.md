
0. Install jq and ruby 2.2.x locally

1. Configure AWS credentials in your environment.  Will need authz to create instances and CodePipeline pipelines and all that good stuff.

2. Add local secrets for your "tier", e.g. "dev".  Add file: tier/dev_secret.yml with format:

        ---
        jenkins_ingress_ssh_cidr: xx.xx.xx.xx/32
        
        GitHubUser: xxxxx
        GitHubToken: xxxxx
        
        jenkins_user: xxxx
        jenkins_pass: xxxx

3. Run bundle install

4. Run inspector_provisioning/provision.sh to setup book-keeping in AWS Inspector

5. Run pipeline/converge_pipeline.rb dev.  Yes I was lazy and 3 and 4 could be collapsed into one script.