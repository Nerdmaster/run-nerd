<?php
  require_once('/home/nerdbuc/websites/PathVars.inc.php');
  require_once(HOME_PHP_INC_PATH . '/facebook/run_nerd.config.php');
  require_once(HOME_PHP_INC_PATH . '/PRNG.php');

  // the facebook client library
  require_once(HOME_DISK_PATH . '/games/fbapi/facebook.php');

  $facebook = new Facebook($api_key, $secret);
  $facebook->require_frame();
  $user = $facebook->require_login();

  // TODO: Create a record for this game in our games table, send game_id and seed to flash app
  $seed = PRNG.seed((1000 + $user) * time());
?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:fb="http://www.facebook.com/2008/fbml">
<body>
<script src="http://static.ak.connect.facebook.com/js/api_lib/v0.4/FeatureLoader.js.php/en_US" type="text/javascript"></script>

<table border="0" cellspacing="0" cellpadding="0">
  <tr valign="center"><td>
    <fb:fan profile_id="236091175782" stream="0" connections="0" logobar="0" width="220"></fb:fan>
  </td><td style="padding-left: 8px;">
    <fb:bookmark></fb:bookmark>
  </td><td style="padding-left: 8px;">
  </td></tr>
</table>

<div align="left" style="float:left; width: 120px; overflow:hidden; padding-top: 20px; clear:both;">
  <div class="TextButton">
    <a target="_blank" href="http://www.nerdbucket.com">Nerdbucket Games</a>
  </div>
</div>
<div align="right">
  <script language="javascript"> AC_FL_RunContent = 0; </script>
  <script language="javascript"> DetectFlashVer = 0; </script>
  <script src="AC_RunActiveContent.js" language="javascript"></script>
  <script language="JavaScript" type="text/javascript">
  <!--
  // -----------------------------------------------------------------------------
  // Globals
  // Major version of Flash required
  var requiredMajorVersion = 9;
  // Minor version of Flash required
  var requiredMinorVersion = 0;
  // Revision of Flash required
  var requiredRevision = 45;
  // -----------------------------------------------------------------------------
  // -->
  </script>
  </head>
  <body bgcolor="#ffffff">
  <script language="JavaScript" type="text/javascript">
  <!--
  if (AC_FL_RunContent == 0 || DetectFlashVer == 0) {
    alert("This page requires AC_RunActiveContent.js.");
  } else {
    var hasRightVersion = DetectFlashVer(requiredMajorVersion, requiredMinorVersion, requiredRevision);
    if(hasRightVersion) {  // if we've detected an acceptable version
      // embed the flash movie
      AC_FL_RunContent(
        'codebase', 'http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,45,0',
        'width', '572',
        'height', '560',
        'src', 'run_nerd?seed=<?php echo $seed ?>&game_id=<?php echo $game_id ?>',
        'quality', 'high',
        'pluginspage', 'http://www.macromedia.com/go/getflashplayer',
        'align', 'middle',
        'play', 'true',
        'loop', 'true',
        'scale', 'showall',
        'wmode', 'opaque',
        'devicefont', 'false',
        'id', 'run_nerd',
        'bgcolor', '#ffffff',
        'name', 'run_nerd',
        'menu', 'false',
        'allowScriptAccess','sameDomain',
        'allowFullScreen','true',
        'movie', 'run_nerd',
        'salign', ''
        ); //end AC code
    } else {  // flash is too old or we can't detect the plugin
      var alternateContent = 'This content requires the Adobe Flash Player: <a href=http://www.macromedia.com/go/getflash/>Get Flash</a>';
      document.write(alternateContent);  // insert non-flash content
    }
  }
  // -->
  </script>
  <noscript>
      This content requires the Adobe Flash Player and JavaScript to be enabled.
      <a href="http://www.macromedia.com/go/getflash/">Get Flash</a>
  </noscript>
</div>

<script type="text/javascript">
  FB_RequireFeatures(["XFBML"], function()
  {
    FB.Facebook.init("<?php echo $api_key ?>", "xd_receiver.htm");
  });
</script>
</body>
</html>
