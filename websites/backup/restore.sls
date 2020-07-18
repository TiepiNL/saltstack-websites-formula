# @TODO docs

# https://docs.saltstack.com/en/latest/ref/states/all/salt.states.archive.html

...:
  archive.extracted:
    # Directory into which the archive should be extracted.
    - name: /var/www
    # Archive to be extracted.
    - source: salt://foo/bar/myapp.zip
