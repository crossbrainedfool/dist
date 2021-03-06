#!/bin/bash

# Ths will update the base installers used by seattelgeni from what
# is currently checked out as trunk. See constants below.
#
# You will need sudo privileges to use this. Don't run this as sudo, it will
# invoke sudo when it needs it.
#
# Usage: ./rebuild_base_installers_for_seattlegeni.sh VERSION_STRING

VERSION=$1

SOFTWARE_UPDATE_URL=http://seattlesoftwareupdater.poly.edu/updatesite/
PUBLIC_KEY_FILE=/path/to/softwareupdater.publickey
PRIVATE_KEY_FILE=/path/to/softwareupdater.privatekey

e=`cat $PUBLIC_KEY_FILE | cut -d' ' -f 1`
n=`cat $PUBLIC_KEY_FILE | cut -d' ' -f 2`
SOFTWARE_UPDATE_KEY="{'e':$e, 'n':$n}"

REPO_PARENT_DIR=/home/release/SeattleTestbed

BASE_INSTALLER_DIRECTORY=/var/www/dist

BASE_INSTALLER_ARCHIVE_DIR=/var/www/dist/old_base_installers

USER=geni

# Check variables first
if [ "$VERSION" == "" ]; then
  echo "You must supply a version string."
  echo "usage: $0 version"
  exit 1
fi

if [ "$SOFTWARE_UPDATE_URL" == "" ]; then
  echo "SOFTWARE_UPDATE_URL isn't set."
  exit 1
fi

if [ ! -d "$BASE_INSTALLER_DIRECTORY" ]; then
  echo "BASE_INSTALLER_DIRECTORY doesn't exist."
  exit 1
fi

if [ ! -d "$BASE_INSTALLER_ARCHIVE_DIR" ]; then
  echo "BASE_INSTALLER_ARCHIVE_DIR doesn't exist."
  exit 1
fi

if [ ! -d "$REPO_PARENT_DIR" ]; then
  echo "REPO_PARENT_DIR doesn't exist."
  exit 1
fi

if [ "`grep -F "$VERSION" $REPO_PARENT_DIR/nodemanager/nmmain.py`" == "" ]; then
  echo "You need to set the version string in $REPO_PARENT_DIR/nodemanager/nmmain.py"
  exit 1
fi

UPDATE_URL_FOUND=$(grep -F "softwareurl = \"$SOFTWARE_UPDATE_URL\"" $REPO_PARENT_DIR/softwareupdater/softwareupdater.py)

if [ "$UPDATE_URL_FOUND" == "" ]; then
  echo "Did not find the correct update url in $REPO_PARENT_DIR/softwareupdater/softwareupdater.py"
  exit 1
fi

UPDATE_KEY_FOUND=$(grep -F "$SOFTWARE_UPDATE_KEY" $REPO_PARENT_DIR/softwareupdater/softwareupdater.py)

if [ "$UPDATE_KEY_FOUND" == "" ]; then
  echo "Did not find the correct update key in $REPO_PARENT_DIR/softwareupdater/softwareupdater.py"
  exit 1
fi

if ! id $USER >/dev/null 2>/dev/null ; then
  echo "User account '$USER' does not exist."
  exit 1
fi


# Now let's start building!
echo "Archiving old base installers to $BASE_INSTALLER_ARCHIVE_DIR"
echo "Warning: failure after this point may leave seattlegeni with no base installers!"
sudo mv -f $BASE_INSTALLER_DIRECTORY/seattle_* $BASE_INSTALLER_ARCHIVE_DIR

echo "Building new base installers at $BASE_INSTALLER_DIRECTORY"
sudo python $REPO_PARENT_DIR/dist/make_base_installers.py \
  a \
  $REPO_PARENT_DIR \
  $PUBLIC_KEY_FILE \
  $PRIVATE_KEY_FILE \
  $BASE_INSTALLER_DIRECTORY \
  $VERSION

if [ "$?" != "0" ]; then
  echo "Building base installers failed."
  exit 1
fi

echo "Changing base installer symlinks used by seattlegeni."

pushd $BASE_INSTALLER_DIRECTORY

if [ ! -f "seattle_${VERSION}_android.zip" ] || [ ! -f "seattle_${VERSION}_linux.tgz" ] || [ ! -f "seattle_${VERSION}_mac.tgz" ] || [ ! -f "seattle_${VERSION}_win.zip" ]; then
  echo "The base installers don't appear to have been created."
  exit 1
fi

sudo chown $USER seattle_*

sudo -u $USER ln -s -f seattle_${VERSION}_linux.tgz seattle_linux.tgz
sudo -u $USER ln -s -f seattle_${VERSION}_mac.tgz seattle_mac.tgz
sudo -u $USER ln -s -f seattle_${VERSION}_win.zip seattle_win.zip
sudo -u $USER ln -s -f seattle_${VERSION}_android.zip seattle_android.zip
popd

echo "New base installers created and installed for seattlegeni."

