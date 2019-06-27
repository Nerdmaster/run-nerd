#!/bin/bash
# When developing on server, this locally copies files - no need to over-complicate things to save ssh and scp
# calls, so this won't quite match deploy.sh

NERD_PATH=/home/nerdbuc/websites/nerdbucket.com/games/run_nerd

# Now copy all required files to server
cp AC_RunActiveContent.js $NERD_PATH/
cp website/index.php $NERD_PATH/
cp website/facebook/* $NERD_PATH/facebook/

# Now use the power of the server to copy the swf and JS files
cp $NERD_PATH/*.swf $NERD_PATH/facebook/
cp $NERD_PATH/*.js $NERD_PATH/facebook/

# Config file belongs in a semi-safe location
mv $NERD_PATH/facebook/run_nerd.config.php /home/nerdbuc/websites/php_include/facebook/run_nerd.config.php
# Facebook test "deployment"
cp $NERD_PATH/facebook/* $NERD_PATH/test/
