svn-export
==========

Exports only modified or newly added files between two revisions from the SVN repository.

Usage
-----

    svn-export [REPOSITORY] <REVISION_FROM:REVISION_TO> <TARGET>

Install
-------

    TMP="$(mktemp -d)" \
      && git clone http://git.simpledrupalcloud.com/simpledrupalcloud/svn-export.git "${TMP}" \
      && sudo cp "${TMP}/svn-export.sh" /usr/local/bin/svn-export
