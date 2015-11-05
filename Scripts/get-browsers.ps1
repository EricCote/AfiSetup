
     
          
     $fireLink = "http://download.cdn.mozilla.net/pub/mozilla.org/firefox/releases/latest/win32/en-US/"
     $dest=  $env:USERPROFILE + "\downloads\"
     $fr= "http://download.cdn.mozilla.net/pub/mozilla.org/firefox/releases/latest/win32/xpi/fr.xpi"

     $wc = new-object System.Net.WebClient
     $wc.DownloadFile($fr,$dest + "fr_language_.xpi")

     $document = Invoke-WebRequest $fireLink -UseBasicParsing
     #$linkname=($document.Links | where innerText -like "Firefox*" | select -first 1).href
     $linkname=($document.Links | where outerHTML -like "*Firefox Setup*" | where outerHTML -NotLike  "*Stub*" | select -last 1).href 

     #$wc.DownloadFile($fireLink + $linkName, $dest + ("firefox_Setup.exe"))   #[System.Web.HttpUtility]::UrlDecode($linkname)))
     "http://download.cdn.mozilla.net" + $linkName     $wc.DownloadFile("http://download.cdn.mozilla.net" + $linkName, $dest + ("firefox_Setup.exe"))  




     #----
     $chromelink = "http://dl.google.com/edgedl/chrome/install/GoogleChromeStandaloneEnterprise.msi" 
     $wc.DownloadFile($chromelink, $dest + "GoogleChrome_setup.msi")


     #----
     $operaBase = "http://ftp.opera.com/ftp/pub/opera/desktop/" 
     $document = Invoke-WebRequest $operaBase -UseBasicParsing
     $linkname= $operaBase + ($document.Links | select -last 1 ).href + "win/" 


     $document = Invoke-WebRequest $linkName -UseBasicParsing
     $filename =  ($document.Links | select -last 1).href
     $downlink= $linkname + $filename

     $wc.DownloadFile($downlink, $dest + "opera_setup.exe")
     $wc.Dispose()



     #---   



