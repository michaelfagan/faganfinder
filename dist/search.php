<?php

  $q = trim($_GET['q']);
  $searchUrl = $_GET['u'];
  $dopost = false;

  if (strlen($q) && preg_match('/^(.*\|x\|)?http(s)?:\/\/(\w+\.)+\w+\//', $searchUrl) == 1) {
      $tmp = explode('|x|', $searchUrl);
      if (count($tmp) > 1 && strlen($tmp[0]) > 0) {
        $searchUrl = $tmp[1];
        $post_var = $tmp[0];
        $dopost = true;
      }
      else if (strpos($searchUrl, '{q}') > 7) {
        header('Location: ' . str_replace('{q}', $q, $searchUrl));
      }
  }

?>
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Fagan Finder: loading your request</title>
    <meta name="robots" content="noindex,nofollow,noarchive">
  </head>
  <body style="font-size:2em;padding:1em">
 
    <?php if ($dopost) { ?>
 
    <form method="post" action="<?php echo $searchUrl ?>">
      <input type="hidden" name="<?php echo $post_var ?>" value="<?php echo $q ?>">
      <input type="submit" value="Click to continue" style="padding:1em;font-size:inherit">
    </form>
 
    <?php } else { ?>
 
      <p>There was a problem with your request.</p>
 
    <?php } ?>
 
  </body>
</html>