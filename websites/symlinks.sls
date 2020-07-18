# State to create symlinks to link cloned website repos to the web-root directory.
# Read the readme.md in the repository for a full description of this state's functionality.

include:
  # Required for requisites.
  - .git_clones

{%- set local_website_destination_directory = salt['pillar.get']('websites:local_website_destination_directory', '/srv/websites') %}
{%- set local_website_destination_directory = local_website_destination_directory.rstrip('/') %}
{%- set web_root_directory = salt['pillar.get']('websites:web_root_directory', '/var/www') %}
{%- set web_root_directory = web_root_directory.rstrip('/') %}

# Loop through the present website repos in pillar.
{%- for present_site_name, site_details in salt['pillar.get']('websites:sites:present', {}).items() %}

  # @TODO: get defaults from defaults.yaml
  {%- set repo_htdocs_dir = site_details.get('repo_htdocs_dir', 'htdocs') %}

# Create a symlink from the web-root location to the website repo.
websites_symlink_present_{{present_site_name}}:
  file.symlink:
    - name: {{web_root_directory}}/{{present_site_name}}
    - target: {{local_website_destination_directory}}/{{present_site_name}}/{{repo_htdocs_dir}}
    - force: True
    - require:
      - websites_repo_present_{{present_site_name}}

{%- endfor %}

# Loop through the absent website repos in pillar.
{%- for absent_site_name in salt['pillar.get']('websites:sites:absent', []) %}

# Remove the symlink.
websites_symlink_absent_{{absent_site_name}}:
  file.absent:
    - name: {{web_root_directory}}/{{absent_site_name}}

{%- endfor %}
