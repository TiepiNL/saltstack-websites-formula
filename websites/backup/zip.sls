# @TODO: docs

include:
  # Required for requisites.
  - websites.symlinks

{%- set site_backup_root_directory = salt['pillar.get']('websites:site_backup_root_directory', '/var/backups/websites') %}
{%- set site_backup_root_directory = site_backup_root_directory.rstrip('/') %}

    # Loop through the present sites in pillar.
{%- for present_site_name in salt['pillar.get']('websites:sites:present', {}) %}
      # Check if backup is configured.
{%-   if salt['pillar.get']('websites:sites:present:' + present_site_name + ':backup', False) %}
{%-     set site_backup = salt['pillar.get']('websites:sites:present:' + present_site_name + ':backup', {}) %}

# @TODO: docs
{%-     if site_backup.get('dirs', False) %}
{%-       set backup_dirs = site_backup.get('dirs') %}
          # Loop through the site's backup dirs in pillar.
{%-       for backup_dir, backup_dir_details in backup_dirs.items() %}

{%-         if backup_dir_details.get('zip_enabled', False) %}
{%-           set zip_source = backup_dir_details.get('source', None) %}
# @TODO: rstrip docs
# @TODO: make function?
{%-           set zip_source = zip_source.rstrip('/') + '/' %}
{%-           set destination_path = site_backup_root_directory + '/' + present_site_name + '/' + backup_dir %}
{%-           set file_prefix = present_site_name + '_' + backup_dir + '_' %}

              # use `strptime` to give the filename a year+month+day+hour, year+month+day, a year+week, or a year+month suffix.
              # * %Y: Year with century as a decimal number.
              # * %m: Month as a zero-padded decimal number.
              # * %d: Day of the month as a zero-padded decimal number.
              # * %H: Hour (24-hour clock) as a zero-padded decimal number.
              # * %G: ISO 8601 year with century representing the year that contains the greater part of the ISO week.
              # * %V: ISO 8601 week as a decimal number with Monday as the first day of the week.
              #       Week 01 is the week containing Jan 4.
              # * %u: ISO 8601 weekday as a decimal number where 1 is Monday.
              # https://docs.saltstack.com/en/latest/topics/jinja/index.html#strftime
              # https://docs.python.org/3/library/datetime.html#strftime-strptime-behavior
{%-           set zip_interval = backup_dir_details.get('zip_interval', '@daily') %}
{%-           if zip_interval == '@hourly' %}
{%-             set zip_filename = file_prefix + 'now'|strftime('%Y%m%d%H') + '.zip' %}
{%-           elif zip_interval == '@weekly' %}
{%-             set zip_filename = file_prefix + 'now'|strftime('%G%V') + '.zip' %}
{%-           elif zip_interval == '@monthly' %}
{%-             set zip_filename = file_prefix + 'now'|strftime('%Y%m') + '.zip' %}
{%-           else %}
                # Use daily (default).
{%-             set zip_filename = file_prefix + 'now'|strftime('%Y%m%d') + '.zip' %}
{%-           endif %}

              # Create archive, only if it doesn't exists.
{%-           if not salt['file.file_exists' ](destination_path + '/' + zip_filename) %}

# Take the files from the source directory and put them in /[destination]/[archive].zip.
# * '-r': Recurse into directories.
# * '-y': Store symbolic links as the link instead of the referenced file.
# * '-T': Test zipfile integrity.
# For a full overview of command options, check:
# https://www.cyberciti.biz/faq/how-to-zip-a-folder-in-ubuntu-linux/
websites_backup_zip_{{backup_dir}}:
  cmd.run:
    - name: zip -r -y -T "{{destination_path}}/{{zip_filename}}" "{{zip_source}}"
    - require:
      - websites_symlink_present_{{present_site_name}}
# @TODO: require pkgs

{%-           else %}

# Verify that the named file or directory is present or exists.
# We just passed the `file.file_exists` test, so we already know
# the positive result, making this a dummy state. Why? to prevent
# a continiously changing amount of states.
websites_backup_zip_{{backup_dir}}:
  file.exists:
    - name: {{destination_path}}/{{zip_filename}}


{%-           endif %}
{%-         endif %}
{%-       endfor %}
{%-     endif %}
{%-   endif %}
{%- endfor %}
