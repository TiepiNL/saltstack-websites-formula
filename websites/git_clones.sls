# Read the readme.md in the repository for a description of this state's functionality.
# Further reference: https://docs.saltstack.com/en/latest/ref/states/all/salt.states.git.html
  
{%- set local_website_destination_directory = salt['pillar.get']('websites:local_website_destination_directory', '/srv/websites') %}
{%- set local_website_destination_directory = local_website_destination_directory.rstrip('/') %}

{%- set github_user = salt['pillar.get']('websites:github_user', '') %}
{%- set github_rsa_deploy_key = salt['pillar.get']('websites:github_rsa_deploy_key', '') %}

# Loop through the present sites in pillar.
{%- for present_site_name, site_details in salt['pillar.get']('websites:sites:present', {}).items() %}
  
  # Default to master, if no specific branch tag is set.
  {%- set site_target_branch = site_details.get('branch', 'master') %}
  {%- if site_details.get('url', False) %}
    {%- set url = site_details.get('url') %}
  {%- else %}
    {%- set url = 'git@github.com:' + github_user + '/' + present_site_name + '.git' %}
  {%- endif %}
# Make sure the website repository is cloned to the given directory and is up-to-date.
websites_repo_present_{{present_site_name}}:
  git.latest:
    - name: {{url}}
    - target: {{local_website_destination_directory}}/{{present_site_name}}
    - rev: {{site_target_branch}}
    - force_checkout: True
    - force_clone: True
    - force_fetch: True
    - force_reset: True
    - identity: {{github_rsa_deploy_key}}

# @TODO: other git params?
#    - depth: 1
#    --single-branch
#    - branch: site_target_branch #master ???

{%- endfor %}


# @TODO: docs
{%- for absent_site_name in salt['pillar.get']('websites:sites:absent', []) %}

# Remove the website repository, if present.
websites_repo_absent_{{absent_site_name}}:
  file.absent:
    - name: {{local_website_destination_directory}}/{{absent_site_name}}

{%- endfor %}
