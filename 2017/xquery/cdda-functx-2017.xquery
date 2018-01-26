xquery version "3.0";

(:~
: User: laszlo
: Date: 1/17/18
: Time: 10:06 AM
: To change this template use File | Settings | File Templates.
:)

module namespace functx = "http://www.functx.com";

declare function functx:if-empty($arg as item()?, $value as item()*) as item()* {
    if (string($arg) != '')
    then data($arg)
    else $value
};

declare function functx:if-absent($arg as item()* , $value as item()*) as item()* {
    if (exists($arg))
    then $arg
    else $value
};

declare function functx:substring-before-if-contains
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string? {

   if (contains($arg,$delim))
   then substring-before($arg,$delim)
   else $arg
 } ;