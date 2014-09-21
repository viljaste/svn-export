svn-export
==========

Exports only modified or newly added files from the SVN repository between two revisions.

    svn-export [REPOSITORY] <REVISION_FROM:REVISION_TO> <TARGET>

Install
-------

    TMP="$(mktemp -d)" \
      && git clone http://git.simpledrupalcloud.com/simpledrupalcloud/svn-export.git "${TMP}" \
      && sudo cp "${TMP}/svn-export.sh" /usr/local/bin/svn-export
