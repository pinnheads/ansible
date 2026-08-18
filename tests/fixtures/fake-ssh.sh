#!/bin/bash
# Installed as /usr/bin/ssh in the test image so the playbook's
# git@github.com:pinnheads/... URLs resolve to local bare repos in /srv/repos.
#
# Faking the transport rather than using git's url.insteadOf, because insteadOf
# also changes what `git ls-remote --get-url` reports, which makes ansible's git
# module think the remote URL changed on every run and report changed forever.
# It is installed as the binary rather than via core.sshCommand because ansible
# sets GIT_SSH_COMMAND itself when accept_hostkey is on, which wins over config.
#
# git invokes: ssh [opts] <host> "git-upload-pack 'pinnheads/repo.git'"
read -r prog path <<<"${*: -1}"
exec "$prog" "/srv/repos/$(basename "${path//\'/}")"
