# svn-export

Exports only modified or newly added files between two revisions from the SVN repository.

## Usage

    svn-export [REPOSITORY] <REVISION_FROM:REVISION_TO> <TARGET>

## Install

    TMP="$(mktemp -d)" \
      && git clone http://git.simpledrupalcloud.com/simpledrupalcloud/svn-export.git "${TMP}" \
      && sudo cp "${TMP}/svn-export.sh" /usr/local/bin/svn-export \
      && sudo chmod +x /usr/local/bin/svn-export

## How to use

### Repository from working directory

    svn-export 26383:HEAD ~/exported_files

### Repository from directory

    svn-export ~/files_under_version_control 26383:HEAD ~/exported_files

### Repository from URL

    svn-export http://repository 26383:27334 ~/exported_files

## License

**MIT**
