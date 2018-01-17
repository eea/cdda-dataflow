xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: CDDA 2017 (Library module)
 :
 : Version:     $Id$
 : Created:     11 January 2018
 : Copyright:   European Environment Agency
 :)
(:~
 : Common utility methods used by CDDA 2017 scripts.
 : Reporting obligation: http://rod.eionet.europa.eu/obligations/32
 :
 : This module contains 3 types of helper methods:
 :      - DD HELPER methods: methods for quering data from Data Dictionary
 :      - UI HELPER methods: methods for building QA results HTML
 :      - Common HELPER methods
 :      - Rule HELPER methods: QA rules related helper methods
 :)
module namespace xmlutil = "http://converters.eionet.europa.eu/cdda/xmlutil";
import module namespace cutil = "http://converters.eionet.europa.eu/cutil" at "cdda-common-util.xquery";
(: UI utility methods for build HTML formatted QA result:)
import module namespace uiutil = "http://converters.eionet.europa.eu/ui" at "cdda-ui-util-2017.xquery";
(: Data Dictionary utility methods:)
import module namespace ddutil = "http://converters.eionet.europa.eu/ddutil" at "cdda-dd-util.xquery";
(: Dataset rule definitions and utility methods:)
import module namespace rules = "http://converters.eionet.europa.eu/cdda/rules" at "cdda-rules-2017.xquery";
(: SPARQL utility methods for querying data from CR :)
import module namespace sparqlutil = "http://converters.eionet.europa.eu/cdda/sparql" at "cdda-sparql-util-2017.xquery";
(: Utility methods for connecting Discomap webservice:)
(:
import module namespace nutsws = "http://converters.eionet.europa.eu/cdda/nutsws" at "cdda-util-nuts-webservice.xquery";
:)
declare namespace dd11 = "http://dd.eionet.europa.eu/namespace.jsp?ns_id=11";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace dd = "http://dd.eionet.europa.eu";
declare namespace ddrdf = "http://dd.eionet.europa.eu/schema.rdf#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs = "http://www.w3.org/2000/01/rdf-schema#";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";

(:~ Constant used for invalid numeric values. :)
declare variable $xmlutil:ERR_NUMBER_VALUE as xs:integer :=  -99999;
(:~ declare Content Registry SPARQL endpoint:)
declare variable $xmlutil:CR_SPARQL_URL := "http://cr.eionet.europa.eu/sparql";
(:~ Separator used in lists expressed as string :)
declare variable $xmlutil:LIST_ITEM_SEP := "##";
(:~ EU boundary: min x :)
declare variable $xmlutil:EU_MIN_X as xs:integer := -32;
(:~ EU boundary: min y :)
declare variable $xmlutil:EU_MIN_Y as xs:integer := 27;
(:~ EU boundary: max x :)
declare variable $xmlutil:EU_MAX_X as xs:integer := 33;
(:~ EU boundary: max y :)
declare variable $xmlutil:EU_MAX_Y as xs:integer := 72;
(:~ declare allowed values for boolean fields :)
declare variable $xmlutil:ALLOWED_BOOLEAN_VALUES as xs:string* := ("true", "false", "1", "0", "y", "n", "yes", "no", "-1");

(:
 : ======================================================================
 :                        QA rules related HELPER methods
 : ======================================================================
 :)
(:~
 : Mandatory values QA check. Check if the row has invalid elements. Return the list of invalid element names.
 : @param $rowElement XML Row element to be checked.
 : @param $mandatoryElems List of mandatory element names.
 : @return List of invalid element names.
 :)
declare function xmlutil:getInvalidMandatoryValues($rowElement as element(),$mandatoryElems as xs:string*)
as xs:string*
{
    for $elemName in $mandatoryElems
    let $isInvalid := xmlutil:isInvalidMandatory($rowElement, $elemName)
    where $isInvalid
    return $elemName
};
(:~
 : Check if the element exists and it has a value. Return TRUE if everything is OK, otherwise FALSE.
 : @param $rowElement XML Row element to be checked.
 : @param $elementName XML element name to be checked.
 : @return Boolean, true if element is invalid.
 :)
declare function xmlutil:isInvalidMandatory($rowElement as element(), $elementName as xs:string)
as xs:boolean
{
    let $elem :=  $rowElement/*[local-name() = substring-after($elementName, ":")]
    let $isMissing:= cutil:isMissing($elem)
    let $value:= if($isMissing = fn:true()) then fn:string("") else fn:normalize-space(string-join($elem, ""))

    let $isempty := cutil:isEmpty($value)
    let $isempty :=
        (: Exception!!!     LAT, LON - fields can be empty if CDDA_Coordinates_code is "02" :)
        if($isempty and ($elementName = ("LAT", "LON") or substring-after($elementName, ":")=("LAT","LON"))  and not(cutil:isMissingOrEmpty($rowElement/*[local-name() ="CDDA_Coordinates_code"][1]))  and string-length($rowElement/*[local-name() ="CDDA_Coordinates_code"][1])=2 and
            fn:normalize-space(string($rowElement/*[local-name() ="CDDA_Coordinates_code"][1])) = "02") then
                fn:false()
        (: Exception!!!  Marine_area_perc is filled if the Major_ecosystem_type = MT.  :)
        else if($isempty and ($elementName= "Marine_area_perc" or substring-after($elementName, ":")="Marine_area_perc")
            and (cutil:isMissingOrEmpty($rowElement/*[local-name() ="Major_ecosystem_type"][1])
            or not(upper-case(fn:normalize-space(string($rowElement/*[local-name() ="Major_ecosystem_type"][1]))) = "MT"))) then
                fn:false()
        (: Exception!!! Category, Law, Lawreference and Agency is mandatory if Right([DESIG_ABBR],2) <> "00" AND Right([DESIG_ABBR],2) <> "99"  :)
        else if($isempty
            and ($elementName = "Category" or substring-after($elementName, ":") = "Category"
            or $elementName = "Law" or substring-after($elementName, ":") = "Law"
            or $elementName = "Lawreference" or substring-after($elementName, ":") = "Lawreference"
            or $elementName = "Agency" or substring-after($elementName, ":") = "Agency")
            and not(cutil:isMissingOrEmpty($rowElement/*[local-name() ="DESIG_ABBR"][1]))
            and string-length($rowElement/*[local-name() ="DESIG_ABBR"][1])>2
            and (ends-with(fn:normalize-space(string($rowElement/*[local-name() ="DESIG_ABBR"][1])),"00")
            or ends-with(fn:normalize-space(string($rowElement/*[local-name() ="DESIG_ABBR"][1])),"99"))) then
                fn:false()
        else
            $isempty

    return $isempty
};

(:~
 : Goes through all elements in one row and reads the data type values.
 : Returns a map, where key = element name and value is a list of true/false values for each entry (normally only 1 value if it is not multivalue element)
 : @param $row XML Row element to be checked.
 _ @param $elemSchemaUrl XML Schema in DD containing elem defs.
 : @param $allElements List of all element names to be checked.
 : @return List of invalid element names and invalid value true/false indexes(in case of multivalue elments).
 :)
declare function xmlutil:getInvalidDataTypeValues($row as element(), $elemSchemaUrl as xs:string, $allElements as xs:string*)
as xs:string*
{
    let $schemaDoc := fn:doc($elemSchemaUrl)/xs:schema
    for $elemName in $allElements
    let $elemName := substring-after($elemName, ":")
    let $isInvalidValues := xmlutil:isInvalidDatatype($row, $elemName, $schemaDoc)
    where not(empty(index-of($isInvalidValues, fn:true())))
    return
        cutil:createHashMapEntry($elemName, cutil:castBooleanSequenceToStringSeq($isInvalidValues))
};

(:~
 : Check if the node exists and it has correct datatype. Return the list of boolean values (TRUE if everything is OK, otherwise FALSE).
 : @param $row XML Row element to be checked.
 : @param $elementName XML element name to be checked
 : @param $schemaDoc xs:schema element from XML Schema
 : @return List of boolean values (valid/invalid tokens)
 :)
declare function xmlutil:isInvalidDatatype($row as element(), $elementName as xs:string, $schemaDoc as element(xs:schema))
as xs:boolean*
{
    let $elements :=  $row/*[local-name()=$elementName]
    for $elem in $elements
        let $isMissing:= cutil:isMissing($elem)
        let $value:= if($isMissing = fn:true()) then fn:string("") else fn:normalize-space(string($elem))

        let $elemSchemaDef := $schemaDoc//xs:element[@name=$elem/local-name()]/xs:simpleType/xs:restriction
        let $datatype := $elemSchemaDef/@base

        let $isInvalid := if ($value = "") then fn:false()
                (: Exception!! YEAR  between 1872 and present year :)
                                else if ($elementName = "YEAR" or substring-after($elementName, ":") = "YEAR") then
                                    xmlutil:isInvalidYear($value)
                                else if(string($datatype)="xs:string") then
                                    xmlutil:isInvalidString($value, $elemSchemaDef, $elem/local-name())
                                else if(string($datatype)="xs:boolean") then
                                    xmlutil:isInvalidBoolean($value, $elemSchemaDef)
                                else if(string($datatype)="xs:decimal") then
                                    xmlutil:isInvalidDecimal($value, $elemSchemaDef)
                                else if(string($datatype)="xs:float") then
                                    xmlutil:isInvalidFloat($value, $elemSchemaDef)
                                else if(string($datatype)="xs:double") then
                                    xmlutil:isInvalidDouble($value, $elemSchemaDef)
                                else if(string($datatype)="xs:integer") then
                                    xmlutil:isInvalidInteger($value, $elemSchemaDef)
                                else if(string($datatype)="xs:date" and  string-length($value)>0) then
                                    xmlutil:isInvalidDate($value, $elemSchemaDef)
                                else
                                    fn:false()
    return $isInvalid
};
(: Exception!! YEAR  between 1872 and present year :)
declare function xmlutil:isInvalidYear($value as xs:string)
as xs:boolean
{
    let $ret:=
        if (string-length($value)=4) then
            fn:false()
        else
            fn:true()

    let $yy:=
        if ($ret=fn:false() and $value castable as xs:integer)
            then fn:number($value)
            else -999

    let $ret:=
        if ($ret=fn:false() and $yy lt fn:year-from-date(fn:current-date())+1 and $yy gt 1800) then
            fn:false()
        else
            fn:true()

    return
                $ret
};

(:~
 : Check minsize and maxsize for String values.
 : @param $value Element value
 : @param $schemaDef xs:restriction element from XML Schema
 : return True if element is invalid.
 :)
declare function xmlutil:isInvalidString($value as xs:string, $schemaDef as element(xs:restriction), $elemName as xs:string)
as xs:boolean
{
    let $min_size := $schemaDef/xs:minLength/@value
    let $max_size := $schemaDef/xs:maxLength/@value

    let $intMin := if ($min_size castable as xs:integer) then fn:number($min_size) else $xmlutil:ERR_NUMBER_VALUE
    let $intMax := if ($max_size castable as xs:integer) then fn:number($max_size) else $xmlutil:ERR_NUMBER_VALUE

    let $isInvalid := if ($intMin != $xmlutil:ERR_NUMBER_VALUE and string-length($value) < $intMin) then fn:true() else fn:false()

(:
    let $isInvalid :=
        if ($isInvalid = fn:false()) then
            if( $intMax != $xmlutil:ERR_NUMBER_VALUE and string-length($value) > $intMax) then
                fn:true()
            else
                fn:false()
        else
            $isInvalid
:)
    (: special cases :)
    let $isInvalid :=
        if ($elemName = "ReportingEntityUniqueCode") then
            if (not($isInvalid)) then not(fn:matches(lower-case($value), "[a-z]")) else $isInvalid
        else
            $isInvalid
    return
        $isInvalid
};
(:~
 : Check boolean values.
 : @param $value Element value
 : @param $schemaDef xs:restriction element from XML Schema
 : return True if element value is invalid.
 :)
declare function xmlutil:isInvalidBoolean($value as xs:string, $schemaDef as element(xs:restriction))
as xs:boolean
{
    let $isInvalid :=
        if ($value castable as xs:boolean or cutil:containsStr($xmlutil:ALLOWED_BOOLEAN_VALUES, fn:lower-case($value))) then
            fn:false()
        else
            fn:true()
    return
        $isInvalid
};
(:~
 : Check decimal values - min/max values, total digits.
 : @param $value Element value
 : @param $schemaDef xs:restriction element from XML Schema
 : return True if element is invalid.
 :)
declare function xmlutil:isInvalidDecimal($value as xs:string, $schemaDef as element(xs:restriction))
as xs:boolean
{
    let $min_val := $schemaDef/xs:minInclusive/@value
    let $max_val := $schemaDef/xs:simpleType/xs:restriction/xs:maxInclusive/@value
    let $totalDigits := $schemaDef/xs:simpleType/xs:restriction/xs:totalDigits/@value

    let $decimalMinVal := if ($min_val castable as xs:decimal) then fn:number($min_val) else $xmlutil:ERR_NUMBER_VALUE
    let $decimalMaxVal := if ($max_val castable as xs:decimal) then fn:number($max_val) else $xmlutil:ERR_NUMBER_VALUE
    let $intTotalDigits := if ($totalDigits castable as xs:integer) then fn:number($totalDigits) else $xmlutil:ERR_NUMBER_VALUE
    let $decimalValue := if ($value castable as xs:decimal or $value castable as xs:float) then fn:number($value) else $xmlutil:ERR_NUMBER_VALUE

    let $invalid := ()
    (: the value can be xs:decimal or s:float :)
    let $invalid := if($value castable as xs:decimal or $value castable as xs:float  or  $value = "") then  $invalid else fn:insert-before($invalid,1,fn:true())

    let $invalid := if( $decimalMinVal=$xmlutil:ERR_NUMBER_VALUE or $decimalValue=$xmlutil:ERR_NUMBER_VALUE or $value = "" or $decimalValue >= $decimalMinVal) then $invalid else fn:insert-before($invalid,1,fn:true())
    let $invalid := if( $decimalMaxVal=$xmlutil:ERR_NUMBER_VALUE or $decimalValue=$xmlutil:ERR_NUMBER_VALUE or $value = "" or $decimalValue <= $decimalMaxVal) then $invalid else fn:insert-before($invalid,1,fn:true())
    (: check totalDigits only, if it xs:decimal, otherwise it is xs:float or empty or erroneous :)
    let $valueTotalDigits := cutil:countTotalDigits($value)
    let $valueTotalDigits := if($valueTotalDigits castable as xs:integer) then $valueTotalDigits else 0
(:  don't check total digits for decimals :)
(:  let $invalid := if( $totalDigits=$xmlutil:ERR_NUMBER_VALUE or $value = "" or ($valueTotalDigits <= $totalDigits and $value castable as xs:decimal) or ($value castable as xs:float and not($value castable as xs:decimal))) then $invalid else fn:insert-before($invalid,1,fn:true()):)

    return
        not(empty(fn:index-of($invalid,fn:true())))
};
(:~
 : Check decimal values - min/max values, total digits.
 : @param $value Element value
 : @param $schemaDef xs:restriction element from XML Schema
 : return True if element is invalid.
 :)
declare function xmlutil:isInvalidFloat($value as xs:string, $schemaDef as element(xs:restriction))
as xs:boolean
{
    let $min_val := $schemaDef/xs:minInclusive/@value
    let $max_val := $schemaDef/xs:maxInclusive/@value

    let $decimalMinVal := if ($min_val castable as xs:decimal) then fn:number($min_val) else $xmlutil:ERR_NUMBER_VALUE
    let $decimalMaxVal := if ($max_val castable as xs:decimal) then fn:number($max_val) else $xmlutil:ERR_NUMBER_VALUE
    let $floatValue := if ($value castable as xs:float) then fn:number($value) else $xmlutil:ERR_NUMBER_VALUE

    let $invalid := ()
    let $invalid := if($value castable as xs:float or  $value = "") then  $invalid else fn:insert-before($invalid,1,fn:true())
    let $invalid := if( $decimalMinVal=$xmlutil:ERR_NUMBER_VALUE or $floatValue=$xmlutil:ERR_NUMBER_VALUE or $value = "" or $floatValue >= $decimalMinVal) then $invalid else fn:insert-before($invalid,1,fn:true())
    let $invalid := if( $decimalMaxVal=$xmlutil:ERR_NUMBER_VALUE or $floatValue=$xmlutil:ERR_NUMBER_VALUE or $value = "" or $floatValue <= $decimalMaxVal) then $invalid else fn:insert-before($invalid,1,fn:true())

    return
        not(empty(fn:index-of($invalid,fn:true())))
}
;
(:~
 : Check double values - min/max values, total digits.
 : @param $value Element value
 : @param $schemaDef xs:restriction element from XML Schema
 : return True if element is invalid.
 :)
declare function xmlutil:isInvalidDouble($value as xs:string, $schemaDef as element(xs:restriction))
as xs:boolean
{
    let $min_val := $schemaDef/xs:minInclusive/@value
    let $max_val := $schemaDef/xs:maxInclusive/@value

    let $decimalMinVal := if ($min_val castable as xs:decimal) then fn:number($min_val) else $xmlutil:ERR_NUMBER_VALUE
    let $decimalMaxVal := if ($max_val castable as xs:decimal) then fn:number($max_val) else $xmlutil:ERR_NUMBER_VALUE
    let $doubleValue := if ($value castable as xs:double) then fn:number($value) else $xmlutil:ERR_NUMBER_VALUE

    let $invalid := ()
    let $invalid := if($value castable as xs:float or  $value = "") then  $invalid else fn:insert-before($invalid,1,fn:true())
    let $invalid := if( $decimalMinVal=$xmlutil:ERR_NUMBER_VALUE or $doubleValue=$xmlutil:ERR_NUMBER_VALUE or $value = "" or $doubleValue >= $decimalMinVal) then $invalid else fn:insert-before($invalid,1,fn:true())
    let $invalid := if( $decimalMaxVal=$xmlutil:ERR_NUMBER_VALUE or $doubleValue=$xmlutil:ERR_NUMBER_VALUE or $value = "" or $doubleValue <= $decimalMaxVal) then $invalid else fn:insert-before($invalid,1,fn:true())

    return
        not(empty(fn:index-of($invalid,fn:true())))
};
(:~
 : Check integer values - min/max values, total digits.
 : @param $value Element value
 : @param $schemaDef xs:restriction element from XML Schema
 : return True if element is invalid.
 :)
declare function xmlutil:isInvalidInteger($value as xs:string, $schemaDef as element(xs:restriction))
as xs:boolean
{
    let $min_val := $schemaDef/xs:minInclusive/@value
    let $max_val := $schemaDef/xs:maxInclusive/@value
    let $totalDigits := $schemaDef/xs:totalDigits/@value

    let $intMinVal := if ($min_val castable as xs:integer) then fn:number($min_val) else $xmlutil:ERR_NUMBER_VALUE
    let $intMaxVal := if ($max_val castable as xs:integer) then fn:number($max_val) else $xmlutil:ERR_NUMBER_VALUE
    let $intTotalDigits := if ($totalDigits castable as xs:integer) then fn:number($totalDigits) else $xmlutil:ERR_NUMBER_VALUE
    let $intValue := if ($value castable as xs:integer) then fn:number($value) else $xmlutil:ERR_NUMBER_VALUE

    let $invalid := ()
    let $invalid := if($value castable as xs:integer or  $value = "") then  $invalid else fn:insert-before($invalid,1,fn:true())
    let $invalid := if( $intMinVal=$xmlutil:ERR_NUMBER_VALUE or $intValue=$xmlutil:ERR_NUMBER_VALUE or $value = "" or $intValue >= $intMinVal) then $invalid else fn:insert-before($invalid,1,fn:true())
    let $invalid := if( $intMaxVal=$xmlutil:ERR_NUMBER_VALUE or $intValue=$xmlutil:ERR_NUMBER_VALUE or $value = "" or $intValue <= $intMaxVal) then $invalid else fn:insert-before($invalid,1,fn:true())
    let $invalid := if( $intTotalDigits=$xmlutil:ERR_NUMBER_VALUE or $value = "" or string-length($value) <= $totalDigits) then $invalid else fn:insert-before($invalid,1,fn:true())

    return
        not(empty(fn:index-of($invalid,fn:true())))
};
(:~
 : Check date values - YYYY-MM-DD format.
 : @param $value Element value
 : @param $schemaDef xs:restriction element from XML Schema
 : return True if element is invalid.
 :)
declare function xmlutil:isInvalidDate($value, $schemaDef as element(xs:restriction))
 as xs:boolean
 {
    let $ret:=
        if (string-length($value)=10) then
            fn:false()
        else
            fn:true()

    let $yy:=
        if ($ret=fn:false() and (fn:substring($value,1,4) castable as xs:integer))
            then fn:number(fn:substring($value,1,4))
            else -999

    let $m:=
        if ($ret=fn:false() and (fn:substring($value,6,2) castable as xs:integer))
            then fn:number(fn:substring($value,6,2))
            else -999

    let $d:=
        if ($ret=fn:false() and (fn:substring($value,9,2) castable as xs:integer))
            then fn:number(fn:substring($value,9,2))
            else -999
    (:check year :)
    let $ret:=
        if ($ret=fn:false() and $m lt 13 and $m gt 0) then
            fn:false()
        else
            fn:true()

    (:check month :)
    let $ret:=
        if ($ret=fn:false() and $yy gt 1900) then
            fn:false()
        else
            fn:true()

    (:check day :)
    let $ret:=
        if ($ret=fn:false() and $d lt 32 and $d gt 0) then
            fn:false()
        else
            fn:true()

    let $ret:=
        if ($ret=fn:false() and fn:substring($value,5,1)="-" and fn:substring($value,5,1)="-") then
            fn:false()
        else
            fn:true()

    let $ret:=
        if ($ret=fn:false() and $value castable as xs:date) then
            fn:false()
        else
            fn:true()

    return
        $ret
};
(:~
 : Build HTML table for displaying data types rules defined in XML Schema.
 : @param $elemSchemaUrl XML Schema URL containing element definitions.
 : @param $allElements List of all elements
 : return HTML table element.
 :)
declare function xmlutil:buildDataTypeDefs($elemSchemaUrl as xs:string, $allElements as xs:string*)
as element(table)
{
    <table class="datatable" border="1">
        <tr>
            <th>Element name</th>
            <th>Data type</th>
            <th>Min size</th>
            <th>Max size</th>
            <th>Min value</th>
            <th>Max value</th>
            <th>Total digits</th>
        </tr>{
        xmlutil:buildDataTypeDefsRows($elemSchemaUrl, $allElements)
    }</table>
};
(:~
 : Build HTML table rows for displaying data types rules defined in XML Schema.
 : @param $elemSchemaUrl XML Schema URL containing element definitions.
 : @param $allElements List of all elements
 : return HTML tr elements.
 :)
declare function xmlutil:buildDataTypeDefsRows($elemSchemaUrl as xs:string, $allElements as xs:string*)
as element(tr)*
{
    let $schemaDoc := fn:doc($elemSchemaUrl)/xs:schema
    let $allElementsWithoutNs := cutil:getElementsWithoutNs($allElements)
    for $pn in $schemaDoc/xs:element
    let $elemName := fn:string($pn/@name)
     let $minValue := if($pn/@name="YEAR") then
                                     1873
                                 else
                                        fn:string($pn/xs:simpleType/xs:restriction/xs:minInclusive/@value)
     let $maxValue := if($pn/@name="YEAR") then
                                     fn:string(fn:year-from-date(fn:current-date())-1)
                                 else
                                     fn:string($pn/xs:simpleType/xs:restriction/xs:maxInclusive/@value)

    where not(empty(index-of($allElementsWithoutNs,fn:string($pn/@name))))
    return
        <tr>
            <td>{ fn:string($pn/@name) }</td>
            <td>{ fn:string($pn/xs:simpleType/xs:restriction/@base) }</td>
            <td>{ fn:string($pn/xs:simpleType/xs:restriction/xs:minLength/@value) }</td>
            <td>{ fn:string($pn/xs:simpleType/xs:restriction/xs:maxLength/@value) }</td>
            <td>{ $minValue }</td>
            <td>{ $maxValue }</td>
            <td>{ fn:string($pn/xs:simpleType/xs:restriction/xs:totalDigits/@value) }</td>
        </tr>
};
(:~
 : Return the list of numeric values. If value is not castable as numeric, then return 0.
 : @param $row Row element to be checked.
 : @param $elements List of Row child elements
 : @return List of numeric values for given XML elements.
 :)
declare function xmlutil:getElementsNumValues($row as element(), $elements as xs:string*)
as xs:decimal*{
    for $elemName in $elements
        for $elem in $row//*[local-name() = $elemName]
        let $value := fn:data($elem)
        return
            if ($value castable as xs:double) then
               xs:decimal($value)
            else
                0
};

(:~
 : Get the list of distinc errror codes in ascending order from the semicolon separated string of error codes.
 : @param $allErrors Semicolon separated string of error codes.
 : @return The list of error codes.
 :)
(:declare function xmlutil:getParsedErrorCodes($allErrors as xs:string)
as xs:integer*
{
    let $errors := fn:reverse(fn:distinct-values(fn:tokenize($allErrors, ";")))
    for $e in $errors
    let $strE := substring-after(normalize-space($e), ".")
    where $strE!=""
    order by fn:number($e ) ascending
    return
        $strE
};:)
(:~
 : Get the error codes in correct order.
 : @param $allErrors List of error codes.
 : @return List of error codes.
 :)
(:declare function xmlutil:getOrderedErrorCodes($allErrors as xs:string*)
as xs:integer
{
    let $errors := fn:reverse(fn:distinct-values(fn:tokenize($allErrors, ";")))
    for $e in $allErrors
    order by fn:number($e) ascending
    return
        $e
};:)

(:~
 : Get error messages for sub rules.
 : @param $ruleDefs Rule elements from Rules XML definition.
 : @param $ruleCode Parent rule code
 : @param $subRuleCodes List of sub rule codes.
 : @return List of rule elements matching to sub rule codes.
 :)
declare function xmlutil:getSubRuleDefs($ruleDefs as element(rule)*, $ruleCode as xs:string, $subRuleCodes as xs:string*)
as element(rule)*
{
    for $subRuleCode in $subRuleCodes
        for $ruleDef in $ruleDefs[@code = concat($ruleCode, ".", $subRuleCode)]
            return $ruleDef
};
(:=================================================================================
 : QA rule - : Check duplicate rows
 :=================================================================================
 :)
(:~
 : QA rule entry: Check mandatory elements and values.
 : Raises errors when some of the mandatory values are missing.
 : @param $uri XML document URL.
 : @param $ruleCode Rule code in rules XML.
 : @return QA rule results in HTML format.
 :)
declare function xmlutil:executeMandatoryValuesCheck($url as xs:string, $schemaId as xs:string,
    $nsPrefix as xs:string, $keyElement as xs:string, $ruleCode as xs:string, $container)
as element(div)
{
    let $ruleElementNames := rules:getRuleElementNames($schemaId, $nsPrefix, $ruleCode)
    let $errMessage := rules:getRuleMessage($schemaId, $ruleCode)
    let $ruleDef := rules:getRule($schemaId, $ruleCode)

    let $result := xmlutil:checkMandatoryValues($url, $schemaId, $ruleCode, $errMessage, $ruleElementNames, $keyElement, $container)

    return
        uiutil:buildRuleResult($result, $ruleDef, $ruleElementNames, <div/>, $uiutil:RESULT_TYPE_TABLE)
};

(:~
 : Goes through all the Rows checks mandatory values. Returns HTML table rows if invalid values found, otherwise the result is empty.
 : @param $uri XML document URL.
 : @param $ruleCode Rule code in rules XML.
 : @return HTML table rows or empty sequence.
 :)
declare function xmlutil:checkMandatoryValues($url as xs:string, $schemaId as xs:string, $ruleCode as xs:string, $errMessage as xs:string,
    $ruleElements as xs:string*, $keyElement as xs:string, $container)
as element(tr)*
{
    let $mandatoryElements := ddutil:getMandatoryElements($schemaId)
    let $mandatoryElements :=
        if ($schemaId = $rules:SITES_SCHEMA) then
            distinct-values(insert-before($mandatoryElements, 1,
                (concat($rules:SITES_NS_PREFIX, "LAT"), concat($rules:SITES_NS_PREFIX, "LON"), concat($rules:SITES_NS_PREFIX, "Marine_area_perc"))))
        else if ($schemaId = $rules:DESIG_SCHEMA) then
            rules:getDesignationMandatoryElements()
        else
            $mandatoryElements
    let $multiValueElems := ddutil:getMultivalueElements($schemaId)
    let $nsPrefix := cutil:getElemNsPrefix($keyElement)
    let $ruleElements := cutil:getElementsWithNs($ruleElements, $nsPrefix)

    for $rowElement at $pos in fn:doc($url)//*[local-name() = $container]//child::*[local-name() = "Row"]
    let $invalidElems := xmlutil:getInvalidMandatoryValues($rowElement, $mandatoryElements)
    where not(empty($invalidElems))
    order by $pos
    return
        <tr align="right" key="{ fn:data($rowElement/*[local-name() = $keyElement]) }">
            <td>{ $pos }</td>{
            for $elem in $ruleElements
            let $isInvalid := cutil:containsStr($invalidElems, $elem)
            let $elem := substring-after($elem, ":")
            let $errLevel := if($elem = ("iucnCategory", "siteArea", "majorEcosystemType")) then 1 else 2
            return
                uiutil:buildTD($rowElement, $elem, $errMessage, fn:true(), $errLevel, $isInvalid, ddutil:getMultiValueDelim($multiValueElems, $elem), $ruleCode)
        }</tr>
};
(:~
 : QA rule entry: Check duplicate values.
 : Raises errors when some of the rows contain duplicate values.
 : @param $uri XML document URL.
 : @param $ruleCode Rule code in rules XML.
 : @return QA rule results in HTML format.
 :)
declare function xmlutil:executeDuplicatesCheck($url as xs:string, $schemaId as xs:string,
    $nsPrefix as xs:string, $keyElement as xs:string, $ruleCode as xs:string, $dupliateKeyElements as xs:string*, $isSites as xs:boolean, $container as xs:string)
as element(div)
{
    let $ruleElementNames := rules:getRuleElementNames($schemaId, $nsPrefix, $ruleCode)
    let $errMessage := rules:getRuleMessage($schemaId, $ruleCode)
    let $ruleDef := rules:getRule($schemaId, $ruleCode)

    let $result :=
        xmlutil:checkDuplicates($url, $schemaId, $ruleCode, $errMessage, $ruleElementNames,
            $keyElement, $dupliateKeyElements, $container)

    return
        uiutil:buildCommonRuleResult($result, $ruleDef, $ruleElementNames)
};
(:~
 : Goes through all the Rows and checks duplicate values. Returns HTML table rows if invalid values found, otherwise the result is empty.
 : CountryCode, NationalStationID, Year, Month, Day, CASNumber and SampleDepth
 : @param $uri XML document URL.
 : @param $ruleCode Rule code in rules XML.
 : @return HTML table rows or empty sequence.
 :)
declare function xmlutil:checkDuplicates($url as xs:string, $schemaId as xs:string, $ruleCode as xs:string, $errMessage as xs:string,
    $ruleElements as xs:string*, $keyElement as xs:string, $duplicateElements as xs:string*, $container as xs:string)
as element(tr)*
{
    let $rows := fn:doc($url)//*[local-name() = $container]/*[local-name() = "Row"]
    let $multiValueElems := ddutil:getMultivalueElements($schemaId)
    let $nsPrefix := cutil:getElemNsPrefix($keyElement)
    let $ruleElements := cutil:getElementsWithNs($ruleElements, $nsPrefix)

    let $keys :=
        for $duplicateRow in $rows
        return
            xmlutil:getDuplicateKey($duplicateRow, $duplicateElements)
    for $row at $pos in $rows
    let $key := xmlutil:getDuplicateKey($row, $duplicateElements)

    let $i := index-of($keys, $key)
    where fn:count($i) > 1 and xmlutil:getDuplicateKey($row, $duplicateElements)
    order by $pos
    return
        <tr align="right" key="{ fn:data($row/*[local-name() = $keyElement]) }">
            <td>{$pos}</td>{
                for $elemName in $ruleElements
                let $elemNameWithoutNs := substring-after($elemName, ":")
                let $isInvalid := cutil:containsStr($duplicateElements, $elemNameWithoutNs)
                let $errLevel := 2
                return
                    uiutil:buildTD($row, $elemNameWithoutNs, $errMessage, fn:false(), $errLevel, ($isInvalid), ddutil:getMultiValueDelim($multiValueElems, $elemName), $ruleCode)
        }</tr>

};
declare function xmlutil:checkDuplicateSites($url as xs:string, $schemaId as xs:string, $ruleCode as xs:string, $errMessage as xs:string,
    $ruleElements as xs:string*, $keyElement as xs:string)
as element(tr)*
{
    let $rows := fn:doc($url)//child::*[local-name() = "Row"]
    let $nsPrefix := cutil:getElemNsPrefix($keyElement)
    let $multiValueElems := ddutil:getMultivalueElements($schemaId)
    let $ruleElements := cutil:getElementsWithNs($ruleElements, $nsPrefix)
    let $keys :=
        for $duplicateRow in fn:doc($url)//child::*[local-name() = "Row"]
        return
            if (not(cutil:isMissingOrEmpty($duplicateRow/*[local-name() = "SITE_CODE"]))) then
                concat(lower-case(normalize-space(string($duplicateRow/*[local-name() = "SITE_CODE"]))), "##")
            else
                concat("##", lower-case(normalize-space(string($duplicateRow/*[local-name() = "SITE_CODE_NAT"]))))
    for $row at $pos in $rows

    let $key :=
            if (not(cutil:isMissingOrEmpty($row/*[local-name() = "SITE_CODE"]))) then
                concat(lower-case(normalize-space(string($row/*[local-name() = "SITE_CODE"]))), "##")
            else
                concat("##", lower-case(normalize-space(string($row/*[local-name() = "SITE_CODE_NAT"]))))
    let $i := index-of($keys, $key)
    where fn:count($i) > 1
    order by $pos
    return
        <tr align="right" key="{ fn:data($row/*[name() = $keyElement]) }">
            <td>{$pos}</td>{
                for $elemName in $ruleElements
                let $elemNameWithoutNs := substring-after($elemName, ":")
                let $isInvalid := if ($elemNameWithoutNs = "SITE_CODE" and not(cutil:isMissingOrEmpty($row/*[local-name() = "SITE_CODE"]))) then
                        true()
                    else if ($elemNameWithoutNs = "SITE_CODE_NAT" and cutil:isMissingOrEmpty($row/*[local-name() = "SITE_CODE"])) then
                        true()
                    else
                        false()
                return
                    uiutil:buildTD($row, $elemName, $errMessage, fn:false(), 0,($isInvalid), ddutil:getMultiValueDelim($multiValueElems, $elemName), $ruleCode)
        }</tr>

};
declare function xmlutil:getDuplicateKey($row as element(), $duplicateElements as xs:string*)
as xs:string
{
    let $keyValues :=
        for $duplicateElement in  $duplicateElements
        return
            lower-case(xmlutil:getRowElementValue($row, $duplicateElement))
    return
        string-join($keyValues, "##")


};
declare function xmlutil:getRowElementValue($row as element(), $elementName as xs:string)
as xs:string
{
        let $elem :=  $row/*[local-name() = $elementName]
        let $isMissing:= cutil:isMissing($elem)
        let $value:= if($isMissing = fn:true()) then fn:string("") else fn:normalize-space(string-join($elem, ""))
        return $value
};

declare function xmlutil:anyValueNotEmpty($row as element(), $duplicateElements as xs:string*)
as xs:boolean
{
     cutil:containsBoolean(
        for $duplicateElement in $duplicateElements
        return
            xmlutil:getRowElementValue($row, $duplicateElement) = ""
        , fn:true())
};
(:=================================================================================
 : QA rule - : Check field data type and min max values against DD definitions
 :=================================================================================
 :)
(:~
 : QA rule entry: Check values against XML Schema constraints - data types.
 : Raises errors when some of the rows contain invalid values.
 : @param $uri XML document URL.
 : @param $ruleCode Rule code in rules XML.
 : @return QA rule results in HTML format.
 :)
declare function xmlutil:executeDataTypesCheck($url as xs:string, $schemaId as xs:string,
    $nsPrefix as xs:string, $keyElement as xs:string, $ruleCode as xs:string, $container as xs:string)
as element(div)
{
    let $ruleElementNames := rules:getRuleElementNames($schemaId, $nsPrefix, $ruleCode)
    let $errMessage := rules:getRuleMessage($schemaId, $ruleCode)
    let $ruleDef := rules:getRule($schemaId, $ruleCode)

    let $result := xmlutil:checkDataTypes($url, $schemaId, $ruleCode, $errMessage, $ruleElementNames,
            $keyElement, $container)
    let $additionalInfo :=
        <div>
            <p><strong>Element definitions in Data Dictionary:</strong></p>{
            xmlutil:buildDataTypeDefs(ddutil:getDDElemSchemaUrl($schemaId), ddutil:getAllElements($schemaId))
        }</div>

    return
        uiutil:buildRuleResult($result, $ruleDef, $ruleElementNames, $additionalInfo, $uiutil:RESULT_TYPE_TABLE)
};
(:~
 : Goes through all the Rows and checks data types. Returns HTML table rows if invalid values found, otherwise the result is empty.
 : @param $uri XML document URL.
 : @param $ruleCode Rule code in rules XML.
 : @return HTML table rows or empty sequence.
 :)
declare function xmlutil:checkDataTypes($url as xs:string, $schemaId as xs:string, $ruleCode as xs:string, $errMessage as xs:string,
    $ruleElements as xs:string*, $keyElement as xs:string, $container)
as element(tr)*
{
    let $multiValueElems := ddutil:getMultivalueElements($schemaId)
    let $nsPrefix := cutil:getElemNsPrefix($keyElement)
    let $ruleElements := cutil:getElementsWithNs($ruleElements, $nsPrefix)
    let $elemSchemaUrl := ddutil:getDDElemSchemaUrl($schemaId)
    let $allElements := ddutil:getAllElements($schemaId)

    for $row at $pos in fn:doc($url)//*[local-name() = $container]//child::*[local-name() = "Row"]
    let $invalidElems := xmlutil:getInvalidDataTypeValues($row, $elemSchemaUrl, $allElements)
    let $invalidElemKeys := cutil:getHashMapKeys($invalidElems)
    where not(empty($invalidElems))
    order by $pos
    return
        <tr align="right" key="{ fn:data($row/*[local-name() = $keyElement]) }">
            <td>{ $pos }</td>{
                for $elemName in $ruleElements
                let $elemName := substring-after($elemName, ":")
                let $isInvalidElem := cutil:containsStr($invalidElemKeys, $elemName)
                let $isInvalid := if(not($isInvalidElem)) then fn:false() else cutil:getHashMapBooleanValues($invalidElems, $elemName)
                return
                    uiutil:buildTD($row, $elemName, $errMessage, fn:false(), 2,($isInvalid), ddutil:getMultiValueDelim($multiValueElems, $elemName), $ruleCode)
        }</tr>
};

(:=================================================================================
 : QA rule - : Check longitude and latitude values against countries boundaries
 :=================================================================================
 :)
(:~
 : QA rule entry: Check longitude and latitude values
 : Raises errors when some of the rows contain invalid values.
 : @param $uri XML document URL.
 : @param $ruleCode Rule code in rules XML.
 : @return QA rule results in HTML format.
 :)
declare function xmlutil:executeLongLatCheck($url as xs:string, $schemaId as xs:string,
    $nsPrefix as xs:string, $keyElement as xs:string, $ruleCode as xs:string, $longLatElements as xs:string*)
as element(div)
{
    let $countryCode := cutil:getReportingCountry($url)
    let $ruleDef := rules:getRule($schemaId, $ruleCode)

    let $longLatResult := xmlutil:checkCountryLongLat($url, $schemaId, $nsPrefix, $keyElement, $ruleCode, $countryCode, $longLatElements)
    let $warnMess :=if (fn:string-length($countryCode) != 2) then "Could not check the values against reporting country bounding box, because Country Code was not found from envelope metadata." else concat("Reporting country is ",$countryCode)
    return
        if(fn:empty($longLatResult) and fn:string-length($countryCode)=2) then
            uiutil:buildSuccessHeader($ruleDef)
        else if(fn:empty($longLatResult) and fn:string-length($countryCode)!=2) then
            uiutil:buildWarningHeader($ruleDef, $warnMess)
        else
          <div>
            {uiutil:buildFailedHeader($ruleDef, $warnMess)}
            {
                uiutil:getResultInfoTable($longLatResult, $ruleCode, $uiutil:RESULT_TYPE_MINIMAL)
            }
            <div id="detailDiv-{$ruleCode}" style="display: none;">
                <table border="1" class="datatable" error="{ rules:getRuleMessage($schemaId, $ruleDef) }">{
                    uiutil:buildTableHeaderRow(rules:getRuleElementNames($schemaId, $nsPrefix, $ruleCode))
                    }{$longLatResult
                }</table>
            {xmlutil:buildBoundariesTbl($url, $countryCode)
            }</div>
          </div>
};
(:~
 : Goes throug all the Rows in the document and checks if longitudes and latitudes are OK.
 : At first it checks country specific boundaries using country code from envelope level.
 : If envelope leveldoesn't have correct country code, then it uses country code defined in the report.
 : If CountryCode from report doesn't have boundaries, then use eu.
 : @param $uri XML document URL.
 : @param $ruleCode Rule code in rules XML.
 : @return HTML table rows or empty sequence.
 :)
declare function xmlutil:checkCountryLongLat($url as xs:string, $schemaId as xs:string,
    $nsPrefix as xs:string, $keyElement as xs:string, $ruleCode as xs:string, $countryCode as xs:string, $longLatElements as xs:string*)
as element(tr)*
{
    let $allBoundaries := xmlutil:getMinMaxRows()
    let $ruleElems := rules:getRuleElements($schemaId, $nsPrefix, $ruleCode)
    let $errMess := rules:getRuleMessage($schemaId, $ruleCode)
    let $multiValueElems := ddutil:getMultivalueElements($schemaId)
    let $validCoordinates := ()(:if (string-length($countryCode) = 2) then xmlutil:checkAllCoordinates($url, $countryCode, "", $longLatElements) else ():)

    for $row at $pos in fn:doc($url)//child::*[local-name() = "Row"]
    let $isInvalidX1 := xmlutil:isInvalidLongLat($allBoundaries, $row/*[local-name() = $longLatElements[1]][1], fn:true(), $countryCode, "")
    let $isInvalidY1 := xmlutil:isInvalidLongLat($allBoundaries, $row/*[local-name() = $longLatElements[2]][1], fn:false(), $countryCode, "")

    let $invalidNutsMessage := () (:xmlutil:isInvalidLongLatOnMapService($validCoordinates, $row, $longLatElements, $countryCode, $pos):)
    let $isInvalidNuts := not(empty($invalidNutsMessage))

    where $isInvalidX1 or $isInvalidY1 or $isInvalidNuts
    order by $pos
    return
        <tr align="right" key="{ fn:data($row/*[name() = $keyElement]) }">
            <td>{ $pos }</td>
            {()(:
                if ($isInvalidNuts) then
                    <span style="color: blue;font-size:0.8em;">{ $invalidNutsMessage }</span>
                    union <br/>
                else
                    ()
                }{
                if ($isInvalidX1 or $isInvalidY1) then
                    <span style="color: blue;font-size:0.8em;">2. Outside the bounding boxes.</span>
                else
                    ()
            :)}
            {
                for $elemName in $ruleElems
                let $elemNameWithoutNs := substring-after($elemName, ":")
                let $isInvalidElem :=
                    if (($elemNameWithoutNs = $longLatElements[1] and ($isInvalidX1 or $isInvalidNuts) or
                            ($elemNameWithoutNs = $longLatElements[2]  and ($isInvalidY1 or $isInvalidNuts)))) then
                        fn:true()
                    else
                        fn:false()
                return
                    uiutil:buildTD($row, $elemName, $errMess, fn:false(), 0,$isInvalidElem, ddutil:getMultiValueDelim($multiValueElems, $elemName), $ruleCode)
        }</tr>
};
declare function xmlutil:isInvalidLongLatOnMapService($validCoordinates as node()*, $row as element()
    , $longLatElements as xs:string*, $cc as xs:string, $pos as xs:integer)
as xs:string?
{
    let $xIsAvailable := not(cutil:isMissingOrEmpty($row/*[local-name() = $longLatElements[1]][1]))
    let $yIsAvailable := not(cutil:isMissingOrEmpty($row/*[local-name() = $longLatElements[2]][1]))
    let $ccAvailable := string-length($cc) = 2

    let $isInvalidCoordinate := count($validCoordinates//field[@id = concat($cc, "_", $pos) and @status = $cc]) = 0
    let $correctCode := string($validCoordinates//field[@id = concat($cc, "_", $pos)][1]/@status)
    let $invalidMess := "1. Outside the country polygon."

    where $xIsAvailable and $yIsAvailable and $ccAvailable
    return
        if ($isInvalidCoordinate) then
            if (string-length($correctCode) > 0) then
                concat($invalidMess, " The coordinates fall into country: ", $correctCode)
            else
                $invalidMess
        else
            ()
};
(:~
 : Build HTML table rows for displaying countries bounding boxes.
 : @param $countryCodes list of country codes.
 : return HTML tr elements.
 :)
declare function xmlutil:getBoundaries($countryCodes as xs:string*)
as element(tr)*
{
    let $minMaxRows := xmlutil:getMinMaxRows()
    for $row in $minMaxRows
    where fn:empty(fn:index-of($countryCodes, $row/ISO_2DIGIT)) = fn:false()
    return
        <tr align="right">
            <td>{ data($row/ISO_2DIGIT) }</td>
            <td>{ data($row/minx) }</td>
            <td>{ data($row/maxx) }</td>
            <td>{ data($row/miny) }</td>
            <td>{ data($row/maxy) }</td>
        </tr>
}
;
(:~
 : Build empty XML for countries boundaries.
 : return XML.
 :)
declare function xmlutil:getEmptyMinMax()
as element(root){
    <root>
        <row>
            <ISO_2DIGIT/>
            <CNT_ISO_2D/>
            <MIN_CNTRY_/>
            <minx/>
            <miny/>
            <maxx/>
            <maxy/>
        </row>
    </root>
}
;
(:~
 : Return all rows from countries boundaries XML.
 : return XML.
 :)
declare function xmlutil:getMinMaxRows()
as element(row)*{

    let $minMaxRows :=
        if(fn:doc-available($rules:MIN_MAX_URL)) then
            fn:doc($rules:MIN_MAX_URL)//root/row
        else
            xmlutil:getEmptyMinMax()//root/row
    return $minMaxRows
}
;
(:~
 : Build HTML table for displaying countries boundaries.
 : @param $elemSchemaUrl XML Schema URL containing element definitions.
 : @param $allElements List of all elements
 : return HTML tr elements.
 :)
declare function xmlutil:buildBoundariesTbl($url as xs:string, $countryCode as xs:string)
as element(div){

    let $minMaxXmlAvailable := fn:doc-available($rules:MIN_MAX_URL)
    let $envelopeCountryBoundaries := xmlutil:getBoundaries($countryCode)
    let $boundaries :=
        if(fn:count($envelopeCountryBoundaries) = 0) then
            xmlutil:getBoundaries(doc($url)//child::*/child::*[fn:local-name() = 'CountryCode'])
        else
            $envelopeCountryBoundaries
    let $showEuRow := fn:count($envelopeCountryBoundaries) = 0
    return
       if(empty($boundaries)) then
           <div>
                <div>Station longitude should be in range { $xmlutil:EU_MIN_X } ... { $xmlutil:EU_MAX_X } and latitude in range { $xmlutil:EU_MIN_Y } ... { $xmlutil:EU_MAX_Y }</div>{
                 if( fn:not($minMaxXmlAvailable) ) then
                    <div>Warning! Countries boundaries xml file is unavailable at: {$rules:MIN_MAX_URL}</div>
                else
                    <div/>
           }</div>
        else
            <div>
               <p><strong>Checked boundaries:</strong></p>
               <table border="1" class="datatable">
                    <tr>
                        <th>Country code</th>
                        <th>min Lon (x)</th>
                        <th>max Lon (x)</th>
                        <th>min Lat (y)</th>
                        <th>max Lat (y)</th>
                    </tr>{
                    $boundaries
                    }{
                    if ($showEuRow) then
                        <tr align="right">
                            <td>EU</td>
                            <td>{ $xmlutil:EU_MIN_X }</td>
                            <td>{ $xmlutil:EU_MAX_X }</td>
                            <td>{ $xmlutil:EU_MIN_Y }</td>
                            <td>{ $xmlutil:EU_MAX_Y }</td>
                        </tr>
                    else
                        ()
                }</table>
            </div>
};
(:~
 : Check if value is correct longitude or lattitude.
 : @param $value Element value
 : @param $allBoundaries List of all boundaries
 : @param $isLong true, if check longitude; false, if check lattitude
 : @param $envCountryCode country code retreived from envelope XML
 : @param $rowCountryCode country code retreived from reported row
 : return True if element is invalid.
 :)
declare function xmlutil:isInvalidLongLat($allBoundaries as element(row)*, $strValue as xs:string, $isLong as xs:boolean, $envCountryCode as xs:string, $rowCountryCode as xs:string)
as xs:boolean
{
    let $decimalValue :=
        if ($strValue castable as xs:decimal)
            then xs:decimal($strValue)
        else
            $xmlutil:ERR_NUMBER_VALUE

    let $countryCode :=
        if(count($allBoundaries[ISO_2DIGIT = $envCountryCode])>0) then
            $envCountryCode
        else if(count($allBoundaries[ISO_2DIGIT = $rowCountryCode])>0) then
            $rowCountryCode
        else
            "eu"

    let $boundaries := $allBoundaries[ISO_2DIGIT = $countryCode]

    let $isInvalid :=
        if(fn:string-length(fn:normalize-space($strValue)) = 0) then
            fn:false()
        else if($countryCode = "eu" and $isLong) then
            $decimalValue < $xmlutil:EU_MIN_X or $decimalValue > $xmlutil:EU_MAX_X
        else if($countryCode = "eu" and not($isLong)) then
            $decimalValue < $xmlutil:EU_MIN_Y or $decimalValue > $xmlutil:EU_MAX_Y
        else if ($isLong) then
            every $ba in  $boundaries satisfies $decimalValue < xs:decimal($ba/minx)  or  $decimalValue > xs:decimal($ba/maxx)
        else if (not($isLong)) then
            every $ba in  $boundaries satisfies $decimalValue < xs:decimal($ba/miny)  or  $decimalValue > xs:decimal($ba/maxy)
        else
            fn:false()
    return
        $isInvalid
};
(:~
 : Check coordinates against Discomap webservice
 :)
declare function xmlutil:checkAllCoordinates($source_url as xs:string, $cc as xs:string, $coordSys as xs:string, $longLatElements as xs:string*)
as node()*
{
    (: let $projectionParam := if ($coordSys = "EPSG:4258") then "LAEA" else "GCSWGS84" :)
    let $projectionParam := "GCSWGS84"
    (: the request URL might be too long. Group fields into different requests :)
    let $inputPointXmlParamFields := string-join(()(:xmlutil:getInputPointXmlParam($source_url, $cc, $longLatElements):), "")
    let $inputPointXmlParamFieldGroups := tokenize($inputPointXmlParamFields, $xmlutil:LIST_ITEM_SEP)
    let $referenceDatasetParam := "NUTS0"
    let $inputFieldsParam := "x,y,id,code"

    for  $inputPointXmlParamGroup in $inputPointXmlParamFieldGroups
        let $inputPointXmlParam := concat("<fields>", string-join($inputPointXmlParamGroup, ""), "</fields>")
        let $nutsWebserviceUrl := ()(:xmlutil:getNutsWebServiceUrl($inputPointXmlParam, $referenceDatasetParam, $projectionParam, $inputFieldsParam ):)
        return
            ()(:nutsws:callJsonWebservice($nutsWebserviceUrl, "value"):)
};
(:
declare function xmlutil:getNutsWebServiceUrl($inputPointXmlParam as xs:string, $referenceDatasetParam as xs:string,
     $projectionParam as xs:string, $inputFieldsParam as xs:string)
as xs:string
{
    let $params := concat("?inputPointXML=", encode-for-uri($inputPointXmlParam), "&amp;ReferenceDataset=", $referenceDatasetParam, "&amp;inputFields=",
        $inputFieldsParam, "&amp;projection=", $projectionParam, "&amp;f=pjson")

    return
        concat($nutsws:NUTS_WEBSERVICE_URL, $params)
};
declare function xmlutil:getInputPointXmlParam($url as xs:string, $cc as xs:string, $longLatElements as xs:string*) as
xs:string*
{
    for $row at $pos in fn:doc($url)//child::*[local-name() = "Row"]
    let $x := if (cutil:isMissingOrEmpty($row/*[local-name() = $longLatElements[1]][1])) then "" else fn:normalize-space($row/*[local-name() = $longLatElements[1]][1])
    let $y := if (cutil:isMissingOrEmpty($row/*[local-name() = $longLatElements[2]][1])) then "" else fn:normalize-space($row/*[local-name() = $longLatElements[2]][1])

    let $groupSeparator := if ($pos div $nutsws:FIELD_GROUP_SIZE = floor($pos div $nutsws:FIELD_GROUP_SIZE)) then $xmlutil:LIST_ITEM_SEP else ""
    where ($x castable as xs:decimal and xs:decimal($x) < 180 and xs:decimal($x) > -180) and
            ($y castable as xs:decimal and xs:decimal($y) < 90 and xs:decimal($y) > -90)
    return
            concat("<field x=&quot;", $x,
                 "&quot; y=&quot;", $y,
                 "&quot; id=&quot;", $cc, "_", $pos, "&quot; code=&quot;", $cc, "_", $pos ,"&quot;/>", $groupSeparator)
};
:)
(:=================================================================================
 : QA rule - : Check correctness of values against code lists (fixed values)
 :=================================================================================
 :)

(:~
 : QA rule entry: Check values against code lists (fixed or suggested values) defined in DD.
 : Raises errors when some of the rows contain invalid values.
 : @param $uri XML document URL.
 : @param $ruleCode Rule code in rules XML.
 : @return QA rule results in HTML format.
 :)
declare function xmlutil:executeCodeListCheck($url as xs:string, $schemaId as xs:string,
    $nsPrefix as xs:string, $keyElement as xs:string, $ruleCode as xs:string, $container as xs:string)
as element(div)
{
    let $ruleElementNames := xmlutil:getCodeListElementsForDisplay($schemaId, $nsPrefix, $ruleCode, fn:false())
    let $multiValueElems := ddutil:getMultivalueElements($schemaId)
    let $ruleDef := rules:getRule($schemaId, $ruleCode)

    let $result := xmlutil:checkCodeListValues($url, $schemaId, $nsPrefix, $keyElement, $ruleCode, $container)
    let $additionalInfo :=
        <div>
            <p><strong>Codelist values:</strong></p>{
                xmlutil:buildCodelistValuesDefs(ddutil:getDDCodelistXmlUrl($schemaId), $multiValueElems)
        }</div>

    return
        uiutil:buildRuleResult($result, $ruleDef, $ruleElementNames, $additionalInfo, $uiutil:RESULT_TYPE_TABLE_CODES)
};
(:~
 : The function guarantees that all code list elements are displayed in results
 :)
declare function xmlutil:getCodeListElementsForDisplay($schemaId as xs:string, $nsPrefix as xs:string, $ruleCode as xs:string, $showNs as xs:boolean)
as xs:string*
{
    if ($showNs) then
        fn:distinct-values(ddutil:getElemNamesWithNs(fn:insert-before(ddutil:getCodeListElements($schemaId), 1,
            rules:getRuleElementNames($schemaId, $nsPrefix, $ruleCode)), $nsPrefix))
    else
        fn:distinct-values(fn:insert-before(ddutil:getCodeListElements($schemaId), 1,
            rules:getRuleElementNames($schemaId, $nsPrefix, $ruleCode)))
};
(:~
 : Goes through all the Rows and checks values against code lists (fixed or suggested values) defined in DD.
 : @param $uri XML document URL.
 : @param $ruleCode Rule code in rules XML.
 : @return HTML table rows or empty sequence.
 :)
declare function xmlutil:checkCodeListValues($url as xs:string, $schemaId as xs:string,
    $nsPrefix as xs:string, $keyElement as xs:string, $ruleCode as xs:string, $container as xs:string)
as element(tr)*
{
    let $multiValueElems := ddutil:getMultivalueElements($schemaId)
    let $ruleElems := xmlutil:getCodeListElementsForDisplay($schemaId, $nsPrefix, $ruleCode, true())
    let $errMessage := rules:getRuleMessage($schemaId, $ruleCode)

    for $row at $pos in fn:doc($url)//*[local-name() = $container]//child::*[local-name() = "Row"]
    let $invalidElems := xmlutil:getInvalidCodelistValues($row, ddutil:getDDCodelistXmlUrl($schemaId))
    let $invalidElemKeys := cutil:getHashMapKeys($invalidElems)
    where fn:not(fn:empty($invalidElems))
    order by $pos
    return
        <tr align="right" key="{ fn:data($row/*[local-name() = $keyElement]) }">
            <td>{ $pos }</td>{
                for $elemName in $ruleElems
                let $elemNameWithoutNs := substring-after($elemName, ":")
                let $isInvalidElem := cutil:containsStr($invalidElemKeys, $elemNameWithoutNs)
                let $isInvalid := if(not($isInvalidElem)) then fn:false() else cutil:getHashMapBooleanValues($invalidElems, $elemNameWithoutNs)
                let $errLevel := if (
                    cutil:containsBoolean($isInvalid, fn:true())
                    and
                    cutil:containsStr(ddutil:getSuggestedCodeListElements($schemaId), $elemNameWithoutNs))
                    then $uiutil:WARNING_LEVEL
                    else $uiutil:BLOCKER_LEVEL
                return
                    uiutil:buildTD($row, $elemNameWithoutNs, $errMessage, fn:false(), $errLevel,($isInvalid), ddutil:getMultiValueDelim($multiValueElems, $elemName), $ruleCode)
        }</tr>
}
;
(:~
 : Goes through all elements in one row and checks corrext fixed values
 : Returns a map, where key = element name and value is a list of true/false values for each entry (normally only 1 value if it is not multivalue element)
 : @param $row XML Row element to be checked.
 : @param $codeListXmlUrl Url of DD codelists XML
 : @return List of invalid element names and invalid value true/false indexes(in case of multivalue elments).
 :)
declare function xmlutil:getInvalidCodelistValues(
    $row as element(),
    $codeListXmlUrl as xs:string
) as xs:string*
{
    let $codeListValues := fn:doc($codeListXmlUrl)//dd:value-list
    for $codelistElement in $codeListValues
    let $elements :=  $row/*[local-name() = $codelistElement/@element]
    let $fixedValues := $codelistElement//dd:value/lower-case(@value)

    (:let $fixedValues :=
        if ($codelistElement/@element = "CDDA_Dissemination_code") then
            fn:remove($fixedValues, index-of($fixedValues, "00")[1])
        else
            $fixedValues
    :)
    (: if fixed value is boolean, the also the following values are allowed Y, N, yes, no, -1, 1, 0:)
    let $fixedValues := if (cutil:containsStr($fixedValues, "true") and cutil:containsStr($fixedValues, "false")) then
                            fn:distinct-values(fn:insert-before($xmlutil:ALLOWED_BOOLEAN_VALUES, 1, $fixedValues))
                        else
                            $fixedValues

    let $isInvalidValues := xmlutil:isInvalidFixedValues($elements, $fixedValues)
    where not(empty(index-of($isInvalidValues, fn:true())))
    return
        cutil:createHashMapEntry($codelistElement/@element, cutil:castBooleanSequenceToStringSeq($isInvalidValues))
};
(:~
 : @param $row XML Row element to be checked.
 : @param $elements list of XML elements
 : @param $codes List of all fixed values
 : @return List of true/false values
 :)
declare function xmlutil:isInvalidFixedValues($elements as element()*, $codes as xs:string*)
as xs:boolean*
{
    for $elem in $elements
        let $invalidFixedValues := xmlutil:isInvalidFixedValue($elem, $codes)
        return $invalidFixedValues
}
;
(:~
 : @param $row XML Row element to be checked.
 : @param $elem XML element to be checked
 : @param $codes List of all fixed values
 : @return true is invalid code value
 :)
declare function xmlutil:isInvalidFixedValue($elem as element(), $codes as xs:string*)
as xs:boolean
{
    let $isMissing:= cutil:isMissingOrEmpty($elem)
    let $value:= if($isMissing = fn:true()) then "" else fn:normalize-space(string($elem))

    (: Unit values may contain micro sign. Micro sign and Greek small mu have different ascii codes 181 and 956. Both are valid :)
    (:
    let $value := if (fn:starts-with($elem/local-name(), "Unit_")) then fn:replace($value, "&#956;", "&#181;") else $value
    :)

    let $notInCodelist := if($value = "") then fn:false() else fn:empty(fn:index-of($codes, lower-case($value)))

    return $notInCodelist
};

(:~
 : Build HTML table for displaying element codelist values
 : @param $codeListXmlUrl Url of DD codelists XML
 : @param $multiValueDelimiters list of multivalue elements and their delimiters
 : return HTML table elements.
 :)
declare function xmlutil:buildCodelistValuesDefs($codeListXmlUrl as xs:string, $multiValueDelimiters as xs:string*)
as element(table){
    <table class="datatable" border="1">
        <tr>
            <th>Element name</th>
            <th>Fixed/suggested</th>
            <th>Values</th>
            <th>Multivalue delimiter</th>
        </tr>{
            xmlutil:buildFixedValuesDefsRows($codeListXmlUrl, $multiValueDelimiters)
    }</table>
};
(:~
 : Build HTML table rows for displaying code list elements.
 : @param $codeListXmlUrl Url of DD codelists XML
 : @param $multiValueDelimiters list of multivalue elements and their delimiters
 : return HTML tr elements.
 :)
declare function xmlutil:buildFixedValuesDefsRows($codeListXmlUrl as xs:string, $multiValueDelimiters as xs:string*)
as element(tr)*
{
    for $valueList in fn:doc($codeListXmlUrl)//dd:value-list
    let $fixedValues := $valueList//dd:value/@value
    (: if fixed value is boolean, the also the following values are allowed Y, N, yes, no, -1, 1, 0:)
    let $fixedValues := if (cutil:containsStr($fixedValues, "true") and cutil:containsStr($fixedValues, "false")) then
                            fn:distinct-values(fn:insert-before($xmlutil:ALLOWED_BOOLEAN_VALUES, 1, $fixedValues))
                        else
                            $fixedValues
    return
        <tr>
            <td>{ fn:data($valueList/@element) }</td>
            <td>{ if ($valueList/@fixed = 'true' or $valueList/@type = "fixed" or $valueList/@type = "vocabulary") then "Fixed" else "Suggested" }</td>
            <td>{ fn:string-join($fixedValues, ", ")}</td>
            <td>{ ddutil:getMultiValueDelim($multiValueDelimiters, $valueList/@element) }</td>
        </tr>
};

(:========================================================================================================
 : QA rule - Goes through all the Rows checks the country code - has to match the one of reporting country
 :========================================================================================================
 :)
(:~
 : QA rule entry: Check countrycode values.
 : Goes through all the Rows checks the country code - has to match the one of reporting country.
 : @param $url XML document URL.
 : @param $ruleCode Rule code in rules XML.
 : @return QA rule results in HTML format.
 :)
declare function xmlutil:executeCountryCodeCheck($url as xs:string, $schemaId as xs:string,
    $nsPrefix as xs:string, $keyElement as xs:string, $ruleCode as xs:string)
as element(div)
{
    let $countryCode := cutil:getReportingCountry($url)
    let $multiValueElems := ddutil:getMultivalueElements($schemaId)
    let $ruleDef := rules:getRule($schemaId, $ruleCode)
    let $ruleElementNames := xmlutil:getCodeListElementsForDisplay($schemaId, $nsPrefix, $ruleCode, fn:false())
    let $cc_url_available := fn:doc-available($rules:COUNTRY_CODES_URL)
    let $cc_mess := if(fn:string-length($countryCode) != 2) then "NB! Could not find the Country Code from envelope metadata." else concat("Reporting country is ", $countryCode)

    let $codeResult := if($cc_url_available) then xmlutil:checkCountryCode($url, $schemaId, $nsPrefix, $keyElement, $ruleCode, $countryCode) else ()
    return
        if(not($cc_url_available))  then
            uiutil:buildInfoHeader($ruleDef,
                concat("Could not execute the script, because the list of Country Codes is not available at the following URL: http://converters.eionet.europa.eu/xmlfile/", $rules:COUNTRY_CODES_URL), "orange")
        else if (empty($codeResult) and fn:string-length($countryCode) = 2) then
            uiutil:buildSuccessHeader($ruleDef)
        else
            <div>{
                uiutil:buildFailedHeader($ruleDef, $cc_mess)
                }{
                    uiutil:getResultInfoTable($codeResult, $ruleCode, $uiutil:RESULT_TYPE_TABLE_CODES)
                }
                <div id="detailDiv-{$ruleCode}" style="display: none;">
                    <table border="1" class="datatable" error="{ rules:getRuleMessage($schemaId, $ruleCode) }">{
                        uiutil:buildTableHeaderRow($ruleElementNames)
                        }{ $codeResult
                    }</table>
                    <p><strong>Rule definitions:</strong></p>
                    <div>The list of Country codes is available at: <a href="http://converters.eionet.europa.eu/xmlfile/{ $rules:COUNTRY_CODES_URL }">http://converters.eionet.europa.eu/xmlfile/{ $rules:COUNTRY_CODES_URL }</a></div>
                    <table class="datatable" border="1">
                        <tr>
                            <th>Element name</th>
                            <th>Description</th>
                            <th>Allowed values</th>
                        </tr>
                        <tr>
                            <td>PARENT_ISO</td>
                            <td>Must be ISO3 alpha code of the reporting country (ISO2 = {$countryCode})</td>
                            <td>{fn:string-join(xmlutil:getAllowedParentIso3($countryCode),", ")}</td>
                        </tr>
                        <tr>
                            <td>ISO3</td>
                            <td>Must be available for respective PARENT_ISO (ISO2 = {$countryCode})</td>
                            <td>{fn:string-join(xmlutil:getAllowedIso3ByIso2($countryCode),", ")}</td>
                        </tr>{
                        if ($schemaId != $rules:SITEBOUND_SCHEMA and $schemaId != $rules:NATIONALOVERVIEW_SCHEMA) then
                            <tr>
                                <td>DESIG_ABBR</td>
                                <td>4 characters; first two is ISO2 code of respective PARENT_ISO or ISO3 country code; last two can be only numeric from 00 to 99</td>
                                <td></td>
                            </tr>
                        else
                            ()
                        }
                    </table>
                </div>
           </div>
};
(:~
 : Goes through all the Rows checks the country code - has to match the one of reporting country.
 : @param $uri XML document URL.
 : @param $ruleCode Rule code in rules XML.
 : @return HTML table rows or empty sequence.
 :)
declare function xmlutil:checkCountryCode($url as xs:string, $schemaId as xs:string,
    $nsPrefix as xs:string, $keyElement as xs:string, $ruleCode as xs:string, $cc as xs:string)
as element(tr)*
{
    let $multiValueElems := ddutil:getMultivalueElements($schemaId)
    let $ruleElems := xmlutil:getCodeListElementsForDisplay($schemaId, $nsPrefix, $ruleCode, true())
    let $errMessage := rules:getRuleMessage($schemaId, $ruleCode)

    for $row at $pos in fn:doc($url)//child::*[local-name() = "Row"]
    let $isInvalidISO3 := xmlutil:isInvalidCountryCode($row/*[local-name() = "ISO3"][1], $cc)
    let $isInvalidPARENT_ISO := xmlutil:isInvalidCountryCode($row/*[local-name() = "PARENT_ISO"][1], $cc)
    let $isInvalidDESIG_ABBR := xmlutil:isInvalidCountryCode($row/*[local-name() = "DESIG_ABBR"][1], $cc)

    where $isInvalidISO3 or $isInvalidPARENT_ISO or $isInvalidDESIG_ABBR
    order by $pos
    return
        <tr align="right" key="{ fn:data($row/*[name() = $keyElement]) }">
            <td>{ $pos }</td>{
                for $elemName in $ruleElems
                let $elemNameWithoutNs := substring-after($elemName, ":")
                let $isInvalid := if (($elemNameWithoutNs = "ISO3" and $isInvalidISO3)
                        or ($elemNameWithoutNs = "PARENT_ISO" and $isInvalidPARENT_ISO)
                        or ($elemNameWithoutNs = "DESIG_ABBR" and $isInvalidDESIG_ABBR)) then fn:true() else fn:false()
                return
                    uiutil:buildTD($row, $elemName, $errMessage, fn:false(), $uiutil:ERROR_LEVEL,($isInvalid), ddutil:getMultiValueDelim($multiValueElems, $elemName), $ruleCode)
            }</tr>
};
declare function xmlutil:isInvalidCountryCode($pn, $cc as xs:string){

    if (not(cutil:isMissingOrEmpty($pn))) then
        if($pn/local-name() = "ISO3") then
            xmlutil:isInvalidISO3($pn, $cc)
        else if($pn/local-name() = "PARENT_ISO") then
            xmlutil:isInvalidPARENT_ISO($pn, $cc)
        else if($pn/local-name() = "DESIG_ABBR") then
            xmlutil:isInvalidDESIG_ABBR($pn, $cc)
    else
        fn:false()
    else
        fn:false()
}
;

(:PARENT_ISO - see country codes table; must be ISO3 alpha code of the reporting country:)
declare function xmlutil:isInvalidPARENT_ISO($pn, $cc as xs:string){

    let $parent_iso :=xmlutil:getAllowedParentIso3($cc)
    return empty(fn:index-of($parent_iso,normalize-space($pn)))
}
;
(:ISO3 - see country codes table; must be available for respective PARENT_ISO code:)
declare function xmlutil:isInvalidISO3($pn, $cc as xs:string){

    let $parent_iso := normalize-space($pn/../*[local-name() = "PARENT_ISO"])
    let $iso3 :=xmlutil:getAllowedIso3ByParentIso($parent_iso)
    return empty(fn:index-of($iso3,normalize-space($pn)))
}
;
(:DESIG_ABBR - four characters; first two is ISO2 code of respective PARENT_ISO or ISO3 country code; last two can be only numeric from 00 to 99:)
declare function xmlutil:isInvalidDESIG_ABBR($pn, $cc as xs:string){

    let $iso3 := normalize-space($pn/../*[local-name() = "ISO3"])
    let $parent_iso := normalize-space($pn/../*[local-name() = "PARENT_ISO"])
    let $desig_abbr := normalize-space($pn)
    let $allowedIso2 := xmlutil:getAllowedIso2($cc)

    return
        if(string-length($desig_abbr)=4) then
            empty(index-of($allowedIso2,substring($desig_abbr,1,2))) or not(substring($desig_abbr,3,2) castable as xs:integer) or number(substring($desig_abbr,3,2)) lt 0 or number(substring($desig_abbr,3,2)) gt 99
        else if(string-length($desig_abbr)=5) then
            empty(index-of(xmlutil:getAllowedIso3($iso3),substring($desig_abbr,1,3))) or not(substring($desig_abbr,4,2) castable as xs:integer) or number(substring($desig_abbr,4,2)) lt 0 or number(substring($desig_abbr,4,2)) gt 99
        else
            fn:true()
}
;
declare function xmlutil:getAllowedIso3ByIso2($cc as xs:string){

    if(string-length($cc)=2) then
            fn:doc($rules:COUNTRY_CODES_URL)//data[parent_iso3=fn:doc($rules:COUNTRY_CODES_URL)//data[iso2=$cc]/parent_iso3]/iso3
    else
            fn:doc($rules:COUNTRY_CODES_URL)//data/iso3
}
;


declare function xmlutil:getAllowedIso3ByParentIso($cc as xs:string){
    if(string-length($cc)=3) then
            fn:doc($rules:COUNTRY_CODES_URL)//data[parent_iso3=$cc]/iso3
    else
            fn:doc($rules:COUNTRY_CODES_URL)//data/iso3
}
;
declare function xmlutil:getAllowedParentIso3($cc as xs:string){
    if(string-length($cc)=2) then
            fn:doc($rules:COUNTRY_CODES_URL)//data[iso2=$cc]/parent_iso3
    else
            fn:doc($rules:COUNTRY_CODES_URL)//data/parent_iso3
}
;
declare function xmlutil:getAllowedIso2($cc as xs:string)
as xs:string*
{
    let $iso2 :=
        if(string-length($cc) = 2) then
            if ($cc = "GB" or $cc = "UK") then ("GB", "UK") else ($cc)
        else
            fn:doc($rules:COUNTRY_CODES_URL)//data/iso2
    return
        $iso2
}
;
declare function xmlutil:getAllowedIso3($iso3 as xs:string)
as xs:string*
{
    if(string-length($iso3)=3) then
            fn:doc($rules:COUNTRY_CODES_URL)//data[iso3=$iso3]/iso3
    else
            fn:doc($rules:COUNTRY_CODES_URL)//data/iso3
}
;
declare function xmlutil:getIso2ByIso3($iso3_list)
as xs:string
{
    for $iso3 in $iso3_list
    return
        data(doc($rules:COUNTRY_CODES_URL)//data[iso3=$iso3]/iso2[1])
};
(:=================================================================================
 : QA rule - : Check correctness of Site code values against DD site codes vocabulary
 :=================================================================================
 :)

(:~
 : QA rule entry: Check values against site codes defined in DD.
 : Raises errors when some of the rows contain invalid values.
 : @param $uri XML document URL.
 : @param $ruleCode Rule code in rules XML.
 : @return QA rule results in HTML format.
 :)
declare function xmlutil:executeSiteCodesCheck($url as xs:string, $schemaId as xs:string,
    $nsPrefix as xs:string, $keyElement as xs:string, $ruleCode as xs:string, $ruleCodeMissingSiteCode as xs:string)
as element(div)*
{

    let $countryCode := cutil:getReportingCountry($url)
    let $ruleDef := rules:getRule($schemaId, $ruleCode)
    let $ruleDefMissingSiteCode := rules:getRule($schemaId, $ruleCodeMissingSiteCode)

    (: get site codes from CR :)
    (: let $countrySiteCodes := if (fn:string-length($countryCode) = 2) then sparqlutil:executeSparqlQuery(sparqlutil:getSiteCodesQuery($countryCode)) else():)
    (: get site codes from DD :)
    let $countrySiteCodes := if (fn:string-length($countryCode) = 2) then
            doc(concat($sparqlutil:SITE_CODE_GRAPH, "?countryCode=", $countryCode))/rdf:RDF
        else
            ()

    let $siteCodeResult := if (fn:string-length($countryCode) = 2 and not(empty($countrySiteCodes))) then xmlutil:checkSiteCodes($url, $schemaId, $nsPrefix, $keyElement, $ruleCode, $countryCode, $countrySiteCodes) else ()
    let $siteCodeMissingResult := if (fn:string-length($countryCode) = 2 and not(empty($countrySiteCodes))) then xmlutil:checkSiteCodesMissing($url, $schemaId, $nsPrefix, $keyElement, $ruleCodeMissingSiteCode, $countryCode, $countrySiteCodes) else ()

    let $warnMess :=if (fn:string-length($countryCode) != 2) then "Could not check site code values, because Country Code was not found from envelope metadata." else concat("Reporting country is ",$countryCode)
    let $warnSiteCodeMess := if(fn:empty($countrySiteCodes)) then "Could not get the list of allocated site codes from Data Dictionary for country " else ""
    let $result1 :=
        if(fn:empty($siteCodeResult) and fn:string-length($countryCode)=2 and not(empty($countrySiteCodes))) then
            uiutil:buildSuccessHeader($ruleDef)
        else if(fn:empty($siteCodeResult) and fn:string-length($countryCode)!=2) then
            uiutil:buildInfoHeader($ruleDef, $warnMess, "orange")
        else if(fn:empty($countrySiteCodes)) then
            uiutil:buildInfoHeader($ruleDef, concat($warnSiteCodeMess, $countryCode) , "orange")
        else
          <div>
            {
            if (count($siteCodeResult//span[text() = $uiutil:ERROR_FLAG]) > 0) then
                uiutil:buildFailedHeader($ruleDef, $warnMess)
            else
                uiutil:buildWarningHeader($ruleDef, concat($ruleDef/message, " ", $warnMess))
            }
            {
                uiutil:getResultInfoTable($siteCodeResult, $ruleDef/@code, $uiutil:RESULT_TYPE_MINIMAL)
            }
            <div id="detailDiv-{$ruleDef/@code}" style="display: none;">
                <table border="1" class="datatable" error="{ rules:getRuleMessage($schemaId, $ruleDef) }">
                    <tr>
                        <th>Row</th>
                        <th>SITE_CODE</th>
                        <th>Error message</th>
                        <th>Site name</th>
                        <th>Year created</th>
                        <th>Year disappeared/discontinued</th>
                    </tr>
                    {$siteCodeResult
                }</table>
            </div>
           </div>
    let $result2 :=
        if(fn:empty($siteCodeMissingResult) and fn:string-length($countryCode)=2 and not(empty($countrySiteCodes))) then
            uiutil:buildSuccessHeader($ruleDefMissingSiteCode)
        else if(fn:empty($siteCodeMissingResult) and fn:string-length($countryCode)!=2) then
            uiutil:buildInfoHeader($ruleDefMissingSiteCode, $warnMess, "orange")
        else if (empty($countrySiteCodes)) then
            uiutil:buildInfoHeader($ruleDefMissingSiteCode, concat($warnSiteCodeMess, $countryCode) , "orange")
        else
          <div>
            { uiutil:buildFailedHeader($ruleDefMissingSiteCode, $warnMess) }
            {
                uiutil:getResultInfoTable($siteCodeMissingResult, $ruleDefMissingSiteCode/@code, $uiutil:RESULT_TYPE_MINIMAL)
            }
            <div id="detailDiv-{$ruleDefMissingSiteCode/@code}" style="display: none;">
                <table border="1" class="datatable" error="{ rules:getRuleMessage($schemaId, $ruleDefMissingSiteCode) }">
                    <tr>
                        <th>SITE_CODE</th>
                        <th>Site name</th>
                        <th>Year created</th>
                    </tr>
                    {$siteCodeMissingResult
                }</table>
            </div>
          </div>
    return
        $result1 union $result2

};
declare function xmlutil:checkSiteCodes($url as xs:string, $schemaId as xs:string,
    $nsPrefix as xs:string, $keyElement as xs:string, $ruleCode as xs:string, $countryCode as xs:string, $countrySiteCodesRdf as element(rdf:RDF)?)
as element(tr)*
{
    let $errMessage := rules:getRuleMessage($schemaId, $ruleCode)
    let $siteCodeElem := "SITE_CODE"
    let $countrySiteCodes := $countrySiteCodesRdf//skos:Concept[ends-with(ddrdf:countryAllocated/lower-case(@rdf:resource), lower-case($countryCode))]

    for $row at $pos in fn:doc($url)//child::*[local-name() = "Row"]

    let $siteCode := $row//*[local-name() = $siteCodeElem][1]
    let $siteCodeValue := if (cutil:isMissingOrEmpty($siteCode)) then "" else normalize-space($siteCode)
    let $siteCodeInDD := $countrySiteCodes[ddrdf:siteCode = $siteCodeValue]

    let $isNotAllocated := count($siteCodeInDD) = 0

    (: count(sparqlutil:executeSparqlQuery(sparqlutil:getSiteCodeExistsQuery($siteCodeValue))) = 0 :)
    let $searchSiteCodes := if ($isNotAllocated) then doc(concat($sparqlutil:SITE_CODE_GRAPH, "?identifier=", $siteCodeValue)) else ()
    let $doesNotExist :=
        if ($isNotAllocated) then
            count($searchSiteCodes//skos:Concept[ddrdf:siteCode/text() = $siteCodeValue]) = 0
        else
            fn:false()

    let $isDisappeared :=
        count($siteCodeInDD[ddrdf:status = 'DISAPPEARED']) > 0
    let $isDeleted :=
        count($siteCodeInDD[ddrdf:status = 'DELETED']) > 0

    let $errLevel := if ($isDisappeared) then $uiutil:WARNING_LEVEL else $uiutil:ERROR_LEVEL

    where $siteCodeValue != "" and ($isNotAllocated or $isDeleted or $isDisappeared)
    order by $pos
    return
        <tr align="right" key="{ fn:data($row/*[name() = $keyElement]) }">
            <td>{ $pos }</td>{
                uiutil:buildTD($row, concat($nsPrefix,$siteCodeElem), $errMessage, fn:false(), $errLevel,(fn:true()), "", $ruleCode)
            }
            {
            if ($doesNotExist) then
                <td style="text-align:left" colspan="4">The site code does not exist in the database</td>
            else if ($isNotAllocated) then
                <td style="text-align:left" colspan="4">The site code has been allocated to different country</td>
            else if ($isDeleted) then
                <td style="text-align:left">Discontinued site code</td>
            else if ($isDisappeared) then
                <td style="text-align:left">Disappeared site code</td>
            else
                <td/>
            }
            {
            if (not($isNotAllocated)) then
                <td style="text-align:left">{
                    data($siteCodeInDD/ddrdf:siteName)
                }</td>
                union
                <td>{
                    data($siteCodeInDD/ddrdf:yearCreated)
                }</td>
                union
                <td>{
                    if ($isDeleted) then
                        data($siteCodeInDD/ddrdf:yearsDeleted)
                    else if ($isDisappeared) then
                        data($siteCodeInDD/ddrdf:yearsDisappeared)
                    else
                        ""
                }</td>
            else
                ()
            }
        </tr>
}
;
declare function xmlutil:checkSiteCodesMissing($url as xs:string, $schemaId as xs:string,
    $nsPrefix as xs:string, $keyElement as xs:string, $ruleCode as xs:string, $countryCode as xs:string, $countrySiteCodesRdf as element(rdf:RDF)?)
as element(tr)*
{
    let $numOfRows := 100
    let $errMessage := rules:getRuleMessage($schemaId, $ruleCode)
    let $siteCodeElem := "SITE_CODE"
    let $reportedSiteCodes := fn:doc($url)//child::*[local-name() = "Row"]/*[local-name() = $siteCodeElem]/text()

    let $errLevel := $uiutil:ERROR_LEVEL

    let $countrySiteCodes := $countrySiteCodesRdf//skos:Concept[ends-with(ddrdf:countryAllocated/lower-case(@rdf:resource), lower-case($countryCode))]
    let $activeSiteCodes := $countrySiteCodes[ddrdf:status = 'ASSIGNED']

    let $missingSiteCodes :=
        for $siteCode in $activeSiteCodes
        where count(index-of($reportedSiteCodes, $siteCode/ddrdf:siteCode/text())) = 0
        return
            $siteCode
    let $missingSiteCodesCount := count($missingSiteCodes)

    for $siteCode at $pos in $missingSiteCodes

    let $tr :=
        <tr align="right" id="tr{$pos}" style="{ if ($pos > $numOfRows) then "display:none" else "" }">{
            uiutil:getErrorTD(<span>{$siteCode/ddrdf:siteCode/text()}</span>, $errMessage, fn:false(),
                $siteCodeElem, $errLevel, false(), $ruleCode)
            }<td style="text-align:left">{
                $siteCode/ddrdf:siteName/text()
            }</td>
            <td>{
                $siteCode/ddrdf:yearCreated/text()
            }</td>
        </tr>
    let $trJs :=
            if ($pos = $numOfRows and $missingSiteCodesCount > $numOfRows) then
                <tr id="trShow"><td colspan="3">
<script type="text/javascript"> var numOfRows = { $numOfRows + 1 }; var maxRows = { $missingSiteCodesCount };<![CDATA[ function showHideRows(showHide){document.getElementById("tr" + numOfRows).style.display = showHide;for (var i = numOfRows; i != maxRows + 1; i++){document.getElementById("tr" + i).style.display = showHide;if (i == maxRows){break;}}document.getElementById("trHide").style.display = showHide;if (showHide == "") {document.getElementById("trShow").style.display = "none";}else {document.getElementById("trShow").style.display = "";}}]]></script>
                    ... <a href="javascript:void(0)" onclick="showHideRows('');">show all {$missingSiteCodesCount} rows</a></td></tr>
            else if ($pos = $missingSiteCodesCount and $missingSiteCodesCount > $numOfRows) then
                <tr id="trHide" style="display:none"><td colspan="3"><a href="javascript:void(0)" onclick="showHideRows('none');">Hide rows</a></td></tr>
            else
                ()
    return
        $tr union $trJs
};
(:~
 : QA rule entry: Check consistency of different elements and values.
 : @param $uri XML document URL.
 : @param $ruleCode Rule code in rules XML.
 : @return QA rule results in HTML format.
 :)
declare function xmlutil:executeConsistencyCheck($url as xs:string, $schemaId as xs:string,
    $nsPrefix as xs:string, $keyElement as xs:string, $ruleCode as xs:string)
as element(div)
{
    let $ruleElementNames := rules:getRuleElementNames($schemaId, $nsPrefix, $ruleCode)
    let $ruleDef := rules:getRule($schemaId, $ruleCode)

    let $result := xmlutil:checkConsistency($url, $schemaId, $nsPrefix, $ruleElementNames, $keyElement, $ruleCode)

    return
        uiutil:buildCommonRuleResult($result, $ruleDef, $ruleElementNames)
};
(:~
 : Goes through all the Rows checks the consistency of fields.
 : @param $uri XML document URL.
 : @param $ruleCode Rule code in rules XML.
 : @return HTML table rows or empty sequence.
 :)
declare function xmlutil:checkConsistency($url as xs:string, $schemaId as xs:string,
    $nsPrefix as xs:string, $ruleElements as xs:string*, $keyElement as xs:string, $ruleCode as xs:string)
as element(tr)*
{
    let $multiValueElems := ddutil:getMultivalueElements($schemaId)
    let $ruleElems := cutil:getElementsWithNs($ruleElements, $nsPrefix)
    let $errMessage := rules:getRuleMessage($schemaId, $ruleCode)

    let $checkedElems := ("Major_ecosystem_type", "Marine_area_perc")

    for $row at $pos in fn:doc($url)//child::*[local-name() = "Row"]

    let $isInvalidValues :=
        not(cutil:isMissingOrEmpty($row/*[local-name() ="Major_ecosystem_type"][1])) and
        not(cutil:isMissingOrEmpty($row/*[local-name() ="Marine_area_perc"][1])) and
        (normalize-space($row/*[local-name()="Marine_area_perc"][1]) = "100" and not(upper-case(normalize-space($row/*[local-name() ="Major_ecosystem_type"][1])) = "M")
        or
        (normalize-space($row/*[local-name()="Marine_area_perc"][1]) = "0" and not(upper-case(normalize-space($row/*[local-name() ="Major_ecosystem_type"][1])) = "T"))
        )
    where $isInvalidValues
    order by $pos
    return
        <tr align="right" key="{ fn:data($row/*[name() = $keyElement]) }">
            <td>{ $pos }</td>{
                for $elemName in $ruleElems
                let $elemNameWithoutNs := substring-after($elemName, ":")
                let $isInvalid := if (not(empty(index-of($checkedElems, $elemNameWithoutNs)))) then fn:true() else fn:false()
                return
                    uiutil:buildTD($row, $elemName, $errMessage, fn:false(), $uiutil:ERROR_LEVEL,($isInvalid), ddutil:getMultiValueDelim($multiValueElems, $elemName), $ruleCode)
            }</tr>
};

