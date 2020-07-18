# State to sync website backup files to a remote destination over ssh.
#
# See https://www.computerhope.com/unix/rsync.htm for a detailed
# list and explanation of all rsync options.

include:
  - openssh

{%- set fqdn = grains['fqdn'] %}

{%- set site_backup_root_directory = salt['pillar.get']('websites:site_backup_root_directory', '/var/backups/websites') %}
{%- set remote_backup_host = salt['pillar.get']('websites:remote_backup_host', 'localhost') %}
{%- set remote_backup_path = salt['pillar.get'](('websites:remote_backup_path').rstrip('/'), '/var/backups') %}

# Check if the required pillar structure is in place.
{%- if salt['pillar.get']('websites:backup_rsync', False) %}
      # All rsync options configuarable in this state are exlained in the
      # websites pillar.
{%-   set backup_rsync = salt['pillar.get']('websites:backup_rsync', {}) %}
{%-   set prepare = backup_rsync.get('prepare', True) %}
{%-   set delete = backup_rsync.get('delete', True) %}
{%-   set force = backup_rsync.get('force', True) %}
{%-   set update = backup_rsync.get('update', False) %}
{%-   set human_readable = backup_rsync.get('human_readable', True) %}
{%-   set log_file = backup_rsync.get('log_file', '/var/log/rsync/website_backups.log') %}
{%-   set log_file_format = backup_rsync.get('log_file_format', '%i %n%L') %}
{%-   set recursive = backup_rsync.get('recursive', True) %}
{%-   set zip_only_filter = backup_rsync.get('zip_only_filter', True) %}
{%-   set prefer_ipv6 = backup_rsync.get('prefer_ipv6', False) %}
{%-   set bwlimit = backup_rsync.get('bwlimit', '0') %}
{%-   set timeout = backup_rsync.get('timeout', '0') %}
{%-   set dryrun = backup_rsync.get('dryrun', False) %}
{%-   set rsync_user = backup_rsync.get('rsync_user', 'root') %}
{%-   set rsa_rsync_key = backup_rsync.get('rsa_rsync_key', '/root/.ssh/id_rsa') %}


# Extract the key name from the full key path.
{%- set key_split = rsa_rsync_key.split('/') %}
{%- set rsync_key_name = key_split[(key_split|length)-1] %}
# Make sure the (private!) key file for the ssh handshake is in place.
websites_rsync_file_managed_rsa_key:
  file.managed:
    - name: {{rsa_rsync_key}}
    # We don't store private keys in public repos, that's why a different
    # source location is being used here.
# @TODO: get key location from pillar?
    - source: salt://addons/keys/{{rsync_key_name}}
    - makedirs: True
    - user: {{rsync_user}}
    - mode: 600


# Create the config file with the zip filter settings,
# only of zip filtering is active.
{%-   if zip_only_filter %}
{%-     set zip_only_filter_conf = salt['environ.get']('HOME') + '/.config/salt-managed/zip_only_filter.conf' %}

websites_rsync_file_managed_zip-only-filter:
  file.managed:
    - name: {{zip_only_filter_conf}}
    - source: salt://websites/files/zip_only_filter.conf.jinja
    - template: jinja
    - makedirs: True

{%-   endif %}


# Create the rsync log file if it doesn't exist,
# otherwise '--log-file=' will make the state fail.
websites_rsync_log_file:
  file.managed:
    - name: {{log_file}}
    # Parent directories will be created to facilitate the creation of the named file.
    - makedirs: True
    # If the file already exists, the file will not be modified.
    - replace: False
    # Set a header on file creation.
    - contents: |
        # Log file created by salt.
        #
        # State file: websites.backup.rsync 
        # State ID: websites_backup_rsync (rsync.synchronized)
        #
    - order: last
 

# Guarantee that the backup source directory is always copied to the target.
# https://docs.saltstack.com/en/latest/ref/states/all/salt.states.rsync.html
websites_backup_rsync:
  rsync.synchronized:
    # Name of the target directory in '[USER@]HOST:DEST' format (for remote shell push).
    - name: {{rsync_user}}@{{remote_backup_host}}:{{remote_backup_path}}/{{fqdn}}/websites/
    # Source directory.
    - source: {{site_backup_root_directory}}/
    # Create destination directory if it does not exists.
    - prepare: {{prepare}}
    # Delete extraneous files from the destination dirs.
    - delete: {{delete}}
    # Force deletion of non-empty directories when it is to be replaced by a non-directory.
    # (This is only relevant if deletions are not active.)
    - force: {{force}}
    # Skip files that are newer on the receiver.
    - update: {{update}}
    # Perform a trial run with no changes made.
    - dryrun: {{dryrun}}
    # Pass additional options to rsync, should be included as a list.
    - additional_opts:
      # Rsync will only create the remote directory for one level, meaning
      # that the parent path must exist. Apply solution as described in:
      # https://www.schwertly.com/2013/07/forcing-rsync-to-create-a-remote-path-using-rsync-path/
      - --rsync-path=mkdir -p {{remote_backup_path}}/{{fqdn}}/websites/ && rsync
      # Use ssh as remote shell with key-based authentication.
      - --rsh=ssh -i {{rsa_rsync_key}}
      # Preserve modification times.
      # Note that if this option is not used, the optimization that
      # excludes files that have not been modified cannot be effective.
      # In other words, a missing -t will cause the next transfer to update all files!
      - --times
      # Log what's happening to the specified file.
      - --log-file={{log_file}}
      # Log updates using the specified format.
      - --log-file-format={{log_file_format}}
      # Put restriction on data transfer speed (<KB/S>).
      - --bwlimit={{bwlimit}}
      # Set a maximum I/O timeout in seconds. If no data is transferred for
      # the specified time then rsync will exit.
      - --timeout={{timeout}}
      # Booleans:
{%-   if human_readable %}
      # Output numbers in a human-readable format.
      - --human-readable
{%-   endif %}
{%-   if recursive %}
      # Sync files and directories recursively.
      - --recursive
{%-   endif %}
{%-   if zip_only_filter %}
      # Add a file-filtering rule (*.zip).
      - --include-from={{zip_only_filter_conf}}
{%-   endif %}
{%-   if prefer_ipv6 %}
      # Prefer IPv6 when creating sockets.
      - --ipv6
{%-   endif %}
    - require:
      - sls: openssh
      - file: websites_rsync_file_managed_rsa_key
      - file: websites_rsync_log_file

{%- endif %}

# 2) Move the public(!) key to the remote server.
# 3) Append the public key to the “authorized_keys” on your remote server:
#    ssh -l andy example.cloudapp.net && cat andy-rsync-key.pub >> .ssh/authorized_keys

# @TODO: logrotate extend?
