xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: Common Utility methods (Library module)
 :
 : Version:     $Id$
 : Created:     11 January 2018
 : Copyright:   European Environment Agency
 :)
(:~
 : Common utility methods
 :
 : @author Enriko Käsper
 :)
module namespace cutil = "http://converters.eionet.europa.eu/cutil";
(:
 : ======================================================================
 :                        Common HELPER methods
 : ======================================================================
 :)
(:~
 : Checks if sequence contains given string
 : @param $seq sequence of strings
 : @param $str string to find from sequence
 : @return Boolean value.
 :)
declare function cutil:containsStr($seq as xs:string*, $str as xs:string)
as xs:boolean
{
     fn:not(fn:empty(fn:index-of($seq, $str)))
};

(:~
 : Checks if sequence contains given boolean
 : @param $seq sequence of booleans
 : @param $bool booelan to find from sequence
 : @return Boolean value.
 :)
declare function cutil:containsBoolean($seq as xs:boolean*, $booelan as xs:boolean)
as xs:boolean
{
     fn:not(fn:empty(fn:index-of($seq, $booelan)))
};

(:~
 : Checks if element value is empty or not.
 : @param $value Element value.
 : @return Boolean value.
 :)(:~
 : Checks if element value is empty or not.
 : @param $value Element value.
 : @return Boolean value.
 :)
declare function cutil:isEmpty($value as xs:string)
as xs:boolean
{
     if (fn:empty($value) or fn:string(fn:normalize-space($value)) = "") then
         fn:true()
    else
        fn:false()
};

(:~
 : Checks if XML element is missing or not.
 : @param $node XML node
 : return Boolean value.
 :)
declare function cutil:isMissing($node as node()*)
as xs:boolean
{
    if (fn:count($node) = 0) then
         fn:true()
    else
        fn:false()
};

(:~
 : Checks if XML element is missing or value is empty.
 : @param $node XML element or value
 : return Boolean value.
 :)
declare function cutil:isMissingOrEmpty($node as item()*)
as xs:boolean
{
    if (cutil:isMissing($node)) then
        fn:true()
    else
        cutil:isEmpty(string-join($node, ""))
};

(:~
 : Function removes the file part from the end of URL and appends 'xml' for getting the envelope xml description.
 : @param $url XML File URL.
 : @return Envelope XML URL.
 :)
declare function cutil:getEnvelopeXML($url as xs:string)
as xs:string
 {
    let $col := fn:tokenize($url,'/')
    let $col := fn:remove($col, fn:count($col))
    let $ret := fn:string-join($col,'/')
    let $ret := fn:concat($ret,'/xml')
    return
        if (fn:doc-available($ret)) then
            $ret
        else
             ""
};

(:~
 : Function reads reproting country code from envelope xml. Returns empty string if envelope XML not found.
 : @param $url XML file URL.
 : @return ECountry code.
 :)
declare function cutil:getReportingCountry($url as xs:string)
as xs:string
{
    let $envelopeUrl := cutil:getEnvelopeXML($url)
    let $countryCode := if(string-length($envelopeUrl)>0) then fn:doc($envelopeUrl)/envelope/countrycode else ""
    return
        (:
        "AT"
        $countryCode
        :)
        $countryCode
};

(:~
 : Remove leading or trailing chars from the string.
 : @param $s Original string.
 : @param $c String to be reomved.
 : @return String value.
 :)
declare function cutil:removeChars($s as xs:string, $c as xs:string, $fromTrailing as xs:boolean)
as xs:string
{
    let $idx := if ($fromTrailing) then string-length($s) else 1
    let $new_s := if ($fromTrailing) then substring($s, 1, $idx - 1) else substring-after($s, $c)
    let $new_c := substring($s,$idx,1)
    let $new_c2 := substring($s,$idx,2)

    return
        if ($new_c = $c and $new_c2 != "0.") then
            cutil:removeChars($new_s , $c , $fromTrailing)
        else
            $s
};

(:~
 : Count total digits of the number. Comma, period or other special caharacter
 : and leading or trailing zeros are not considered as a digit.
 : @param $s Original number (in string type).
 : @return Number of digits.
 :)
declare function cutil:countTotalDigits($s as xs:string )
as xs:integer
{
    let $s := replace($s, ",", ".")

    (: remove trailing + or -  :)
    let $s:=
        if (fn:starts-with($s,"+")) then
            substring-after($s,"+")
        else if (fn:starts-with($s,"-")) then
            substring-after($s,"-")
        else
            $s

    (: remove leading zeros :)
    let $s :=  if (fn:starts-with($s,"0")) then string(cutil:removeChars($s, "0", false())) else $s
    (: remove trailing zeros :)
    let $s :=  if (fn:ends-with($s,"0")) then string(cutil:removeChars($s, "0", true())) else $s
    (: remove decimal indicator :)
    let $s := replace($s,"\.","")

    return
        string-length($s)
};

(:~
 : Get key values from the self constructed map - sequence of structured strings.
 : MAP structure: (key1||value1##value2##value3 , key2||value1##value2##value3).
 : @param $map Self constructed map - sequence of strings.
 : @return Sequence of keys
:)
declare function cutil:getHashMapKeys($map as xs:string*)
as xs:string*
{
    for $entry in $map
    return
        fn:substring-before($entry, "||")
};

(:~
 : Get value from the self constructed map - sequence of structured strings.
 : MAP structure: (key1||value1##value2##value3 , key2||value1##value2##value3).
 : @param $map Self constructed map - sequence of strings.
 : @param $key unique key in the map
 : @return value
:)
declare function cutil:getHashMapValue($map as xs:string*, $key as xs:string)
as xs:string*
{
    for $entry in $map
    let $mapKey := fn:substring-before($entry, "||")
    where ($mapKey = $key) or ($mapKey = substring-after($key, ";")) (:ignore namespace :)
    return
        fn:substring-after($entry, "||")
};

(:~
 : Get the list of values from the self constructed Map object - sequence of structured strings.
 : MAP structure: (key1||value1##value2##value3 , key2||value1##value2##value3).
 : @param $map Self constructed map - sequence of strings.
 : @param $key Key value
 : @return Sequence of keys
:)
declare function cutil:getHashMapBooleanValues($map as xs:string*, $key as xs:string)
as xs:boolean*
{
    for $entry in $map
    where fn:starts-with($entry, concat($key,"||"))
    return
        let $values := fn:tokenize(fn:substring-after($entry,"||"), "##")
        for $val in $values
        return
            if ($val="true") then fn:true()
            else if ($val="false") then fn:false()
            else fn:false()
};

(:~
 : Create Map Entry object - key value pair stored in sequnce. Value represents a list of values delimited with ##.
 : MAP structure: (key1||value1##value2##value3 , key2||value1##value2##value3).
 : @param $key Key value.
 : @param $key List of values.
 : @return Map entry object as string.
:)
declare function cutil:createHashMapEntry($key as xs:string, $values as xs:string*)
as xs:string*
{
    concat($key,"||",string-join($values, "##"))
};

(:~
 : Function for sort sequences.
 : @param $seq Sequence of items.
 : @return Sorted sequence.
 :)
declare function cutil:sort($seq as item()*)
as item()*
{
   for $item in $seq
   order by $item
   return $item
 };

 (:~
  : Removes namespaces from the element names.
  : @param $allElements List of XML elements.
  : @return List of XML elemnets without namespaces.ˇ
  :)
 declare function cutil:getElementsWithoutNs($allElements as xs:string*)
 as xs:string*
 {
    for $elem in $allElements
    return
        fn:substring-after($elem, ":")
 };

(:~
  : Removes namespaces from the element names.
  : @param $allElements List of XML elements.
  : @return List of XML elemnets without namespaces.ˇ
  :)
 declare function cutil:getElementsWithNs($allElements as xs:string*, $nsPrefix as xs:string)
 as xs:string*
 {
    let $nsPrefix := if (fn:contains($nsPrefix, ":")) then $nsPrefix else fn:concat($nsPrefix, ":")
    for $elem in $allElements
    return
        fn:concat($nsPrefix, $elem)
 };

(:~
 : Convaert list of booleans into list of strings.
 : @param $booleanValues List of boolean values
 : @return List of string values.
 :)
declare function cutil:castBooleanSequenceToStringSeq($booleanValues as xs:boolean*)
as xs:string*
{
    for $value in $booleanValues
    return
        string($value)
};

(:~
 : Return element namespace prefix with :
 : @param $seq sequence of strings
 : @return String value.
 :)
declare function cutil:getElemNsPrefix($elemName as xs:string)
as xs:string
{
    if (fn:contains($elemName, ":")) then fn:concat(fn:substring-before($elemName, ":"), ":") else ""
};

(:~
 : Return element name without namespace prefix
 : @param $seq sequence of strings
 : @return String value.
 :)
declare function cutil:getElemNameWithoutNs($elemName as xs:string)
as xs:string
{
    if (fn:contains($elemName, ":")) then fn:substring-after($elemName, ":") else $elemName
};

(:~
 : Return element names with namespace prefix
 : @param $elemNames sequence of strings
 : @return Boolean value.
 :)
declare function cutil:getElemNamesWithNs($elemNames as xs:string*, $ns as xs:string)
as xs:string*
{
    for $elemName in $elemNames
    return
        if (fn:contains($elemName, ":")) then $elemName else fn:concat($ns, $elemName)
};

(:~
 : Replaces the given tokens in string. Then number of given tokens and the lenght of replacements list should be equal.
 : @param $str Strin that will be parsed
 : @param $replacements List of replacement values
 : @param $token Token value whihch will be replaced. String can contain several tokens.
 : @return parsed string.
 :)
declare function cutil:replaceTokens($str as xs:string, $replacements as xs:string*, $token as xs:string)
as xs:string
{
    let $tokenizedStr := if (contains($str, $token)) then tokenize($str, $token) else ()
    let $strOut :=
        if (count($replacements) > 0 and count($tokenizedStr) > 0) then
            string-join(
                for $r at $pos in tokenize($str, $token)
                return
                    if ($pos = count($tokenizedStr)) then
                        $r
                    else
                        concat($r, if (count($replacements) >= $pos) then $replacements[$pos] else "")
            , "")
        else
            $str
     return
        $strOut

};

