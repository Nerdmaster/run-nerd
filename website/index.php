<?php
  require_once('/home/nerdbuc/websites/PathVars.inc.php');
  require_once(HOME_DISK_PATH . '/PageCreation.inc.php');

/*  $GameURLs = array(
      '' => array('', '', '', ''),
      'help' => array('Instructions', '', " target='run_nerd_help'", '')
    );*/
  // $HTMLOut will be the final html we output at the end of this script
  $HTMLOut = GetPageTop('Run, Nerd! - Flash word game that really isn\'t a ripoff of Scrabble or Boggle.  Seriously.', 'index',
      '', '');//, $GameURLs);

  // all done, so print it out!
  print $HTMLOut;
?>
<!--Main page content-->
<div align="center">
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
        'src', 'run_nerd',
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
<!--End main page contect-->
<?php
  // now close everything...
  $HTMLOut = '';
  $HTMLOut .= GetPageBot();

  print $HTMLOut;
?>
