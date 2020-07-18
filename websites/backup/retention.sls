# @TODO docs

{%- set private_key = salt['pillar.get']('websites:github_deploy_key', '') %}
{%- set site_backup_root_directory = salt['pillar.get'](('websites:site_backup_root_directory').rstrip('/'), '/var/backups/websites') %}

# Verify that the site_backup_root_directory directory is present or exists.
websites_backup_root_directory_exists:
  file.exists:
    - name: {{site_backup_root_directory}}

    # Loop through the present sites in pillar.
{%- for present_site_name in salt['pillar.get']('websites:sites:present', {}) %}
      # Check if backup is configured.
{%-   if salt['pillar.get']('websites:sites:present:' + present_site_name + ':backup', False) %}
{%-     set site_backup = salt['pillar.get']('websites:sites:present:' + present_site_name + ':backup', {}) %}
# @TODO: docs
{%-     if site_backup.get('retention_enabled', False) %}
{%-       if site_backup.get('retention', False) %}
{%-         set backup_retention_details = site_backup.get('retention') %}
# @TODO: strptime_format
      # Python strptime format string. Defaults to None, which considers
      # all files in the directory to be backups eligible for deletion
      # and uses os.path.getmtime() to determine the datetime.
#      {%- set strptime_format = backup_retention_details.get('strptime_format', None) %}
{%-         set most_recent = backup_retention_details.get('most_recent', 3) %}
{%-         set first_of_hour = backup_retention_details.get('first_of_hour', 0) %}
{%-         set first_of_day = backup_retention_details.get('first_of_day', 0) %}
{%-         set first_of_week = backup_retention_details.get('first_of_week', 0) %}
{%-         set first_of_month = backup_retention_details.get('first_of_month', 0) %}
{%-         set first_of_year = backup_retention_details.get('first_of_year', 'all') %}
{%-       else %}
          # Use default retention settings.
{%-         set strptime_format = None %}
{%-         set most_recent = 3 %}
{%-         set first_of_hour = 0 %}
{%-         set first_of_day = 0 %}
{%-         set first_of_week = 0 %}
{%-         set first_of_month = 0 %}
{%-         set first_of_year = 'all' %}
{%-       endif %}

# @TODO: docs
{%-       if site_backup.get('dirs', False) %}
{%-         set backup_dirs = site_backup.get('dirs') %}
{%-       else %}
{%-         set backup_dirs = [site_backup_root_directory + '/' + present_site_name] %}
{%-       endif %}

          # Loop through the list of backup directories.
{%-       for backup_dir in backup_dirs %}
            # Only set retention if the given backup directory exists.
{%-         if salt['file.directory_exists' ](backup_dir) %}

# Apply retention scheduling to backup storage directory.
# https://docs.saltstack.com/en/latest/ref/states/all/salt.states.file.html#salt.states.file.retention_schedule
websites_backup_retention_{{present_site_name}}_{{backup_dir}}:
  file.retention_schedule:
    # The filesystem path to the directory containing backups to be managed.
    - name: {{backup_dir}}
    # Delete the backups, except for the ones we want to keep.
    - retain:
        # Keep the most recent N files.
        most_recent: {{most_recent}}
        # For the last N hours from now, keep the first file after the hour.
        first_of_hour: {{first_of_hour}}
        # or the last N days from now, keep the first file after midnight.
        first_of_day: {{first_of_day}}
        # For the last N weeks from now, keep the first file after Sunday midnight.
        first_of_week: {{first_of_week}}
        # For the last N months from now, keep the first file after the start of the month.
        first_of_month: {{first_of_month}}
        # For the last N years from now, keep the first file after the start of the year.
        first_of_year: {{first_of_year}}
    # Parse the filename to determine the datetime of the file.
# @TODO:    - strptime_format: {{strptime_format}}
    # Use the timezone from the locale.
    - timezone: None

{%-         endif %}
{%-       endfor %}
{%-     endif %}
{%-   endif %}
{%- endfor %}
