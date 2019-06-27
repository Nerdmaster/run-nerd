#!/bin/bash
# Deploy script to help copy files to appropriate test/live dirs
# Probably a good idea to have ssh keys set up to avoid re-typing pass a bunch

LOGIN=nerdbuc@nerdbucket.com
NERD_PATH=/home/nerdbuc/websites/nerdbucket.com/games/run_nerd

# Now copy all required files to server
if [ "$1" == "--swf" ]; then
  scp run_nerd.swf $LOGIN:$NERD_PATH/
fi
scp AC_RunActiveContent.js $LOGIN:$NERD_PATH/
scp website/index.php $LOGIN:$NERD_PATH/
scp website/rules.json $LOGIN:$NERD_PATH/
scp website/facebook/* $LOGIN:$NERD_PATH/facebook/

echo 'Now using the server to copy files around as necessary'
# Use the server to copy swj files, js files, and move config to a semi-secure location
ssh $LOGIN "cp $NERD_PATH/*.swf $NERD_PATH/facebook/; cp $NERD_PATH/*.js $NERD_PATH/facebook/; mv $NERD_PATH/facebook/run_nerd.config.php /home/nerdbuc/websites/php_include/facebook/run_nerd.config.php"

# Facebook test "deployment"
echo 'Deploying test code'
ssh $LOGIN "cp $NERD_PATH/facebook/* $NERD_PATH/test/"
