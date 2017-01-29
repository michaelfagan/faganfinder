<?php

  function trackEvent($validity, $url) {
    $ga = array(
      'v' => '1',
      'tid' => 'UA-13006445-2',
      'cid' => sprintf(
          '%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
          mt_rand(0, 0xffff),
          mt_rand(0, 0xffff),
          mt_rand(0, 0xffff),
          mt_rand(0, 0x0fff) | 0x4000,
          mt_rand(0, 0x3fff) | 0x8000,
          mt_rand(0, 0xffff),
          mt_rand(0, 0xffff),
          mt_rand(0, 0xffff)
        ),
      'ds' => 'web',
      't' => 'event',
      'ec' => 'No JavaScript',
      'ea' => $validity,
      'el' => $url
    );
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_USERAGENT, $_SERVER['HTTP_USER_AGENT']);
    curl_setopt($ch, CURLOPT_URL, 'https://www.google-analytics.com/collect');
    curl_setopt($ch, CURLOPT_HTTPHEADER, array('Content-type: application/x-www-form-urlencoded'));
    curl_setopt($ch, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_1_1);
    curl_setopt($ch, CURLOPT_POST, TRUE);
    curl_setopt($ch, CURLOPT_POSTFIELDS, utf8_encode(http_build_query($ga)));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_exec($ch);
    curl_close($ch);
  }

  $q = trim($_POST['q']);
  $searchUrl = $_POST['u'];
  $dopost = false;

  if (strlen($q) && preg_match('/^(.*\|x\|)?http(s)?:\/\/(\w+\.)+\w+\//', $searchUrl) == 1) {
      $tmp = explode('|x|', $searchUrl);
      if (count($tmp) > 1 && strlen($tmp[0]) > 0) {
        $searchUrl = $tmp[1];
        $post_var = $tmp[0];
        $dopost = true;
        trackEvent('valid', $searchUrl);
      }
      else if (strpos($searchUrl, '{q}') > 7) {
        trackEvent('valid', $searchUrl);
        header('Location: ' . str_replace('{q}', $q, $searchUrl));
        exit();
      }
      else {
        trackEvent('invalid', $searchUrl);
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