[CmdletBinding()]
Param
    (
    [string]$dest ="c:\dl\"

    )
      
   
      if (-not (test-path $dest)) {  md $dest }

      #$fireLink = "http://download.cdn.mozilla.net/pub/mozilla.org/firefox/releases/latest/win32/en-US/" 
      #$fr= http://download.cdn.mozilla.net/pub/mozilla.org/firefox/releases/latest/win32/xpi/fr.xpi" 
      $fr="https://addons.mozilla.org/firefox/downloads/latest/417178/addon-417178-latest.xpi"
      $fireLink = "https://download.mozilla.org/?product=firefox-latest&os=win&lang=en-US"

      $wc = new-object System.Net.WebClient 
      $wc.DownloadFile($fr,$dest + "fr_language.xpi") 
      $wc.DownloadFile($fireLink, ($dest + "firefox_Setup.exe"))  
     
      #$document = Invoke-WebRequest $fireLink -UseBasicParsing
      #$linkname=($document.Links | where outerHTML -like "*Firefox Setup*" | where outerHTML -NotLike  "*Stub*" | select -last 1).href 

      #"http://download.cdn.mozilla.net" + $linkName

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


