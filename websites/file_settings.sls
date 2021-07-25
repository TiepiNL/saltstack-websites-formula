# State to set the right permissions and ownership to the website files and folders.
# Read the readme.md in the repository for a full description of this state's functionality.

include:
  # Required for requisites.
  - .git_clones
  
{%- set web_root_directory = salt['pillar.get']('websites:web_root_directory', '/var/www') %}
{%- set web_root_directory = web_root_directory.rstrip('/') %}

# Loop through the present website repos in pillar.
{%- for present_site_name, site_details in salt['pillar.get']('websites:sites:present', {}).items() %}

# @TODO: get defaults from defaults.yaml
{%- set dir_mode = site_details.get('dir_mode', '755') %}
{%- set file_mode = site_details.get('file_mode', '644') %}

# Set the right permissions and ownership.
{{web_root_directory}}/{{present_site_name}}:
  file.directory:
    - dir_mode: {{dir_mode}}
    - file_mode: {{file_mode}}
    - recurse:
      - mode
    # follow symlinks and check the permissions of the directory/file
    # to which the symlink points.
    - follow_symlinks: True
    # If allow_symlink is True and the specified path is a symlink,
    # it will be allowed to remain if it points to a directory.
    - allow_symlink: True
    - require:
      - websites_repo_present_{{present_site_name}}

{%- endfor %}
