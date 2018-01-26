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
import module namespace functx = "http://www.functx.com" at "cdda-functx-2017.xquery";
import module namespace cutil = "http://converters.eionet.europa.eu/cutil" at "cdda-common-util.xquery";
(: UI utility methods for build HTML formatted QA result:)
import module namespace uiutil = "http://converters.eionet.europa.eu/ui" at "cdda-ui-util-2017.xquery";
(: Data Dictionary utility methods:)
import module namespace ddutil = "http://converters.eionet.europa.eu/ddutil" at "cdda-dd-util.xquery";
(: Dataset rule definitions and utility methods:)
import module namespace rules = "http://converters.eionet.europa.eu/cdda/rules" at "cdda-rules-2017.xquery";
(: SPARQL utility methods for querying data from CR :)
(:import module namespace sparqlutil = "http://converters.eionet.europa.eu/cdda/sparql" at "cdda-sparql-util-2017.xquery";:)
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
declare variable $xmlutil:ALLOWED_BOOLEAN_VALUES as xs:string* := ("true", "false", "1", "0");

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
};

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
        <div>{
                xmlutil:buildCodelistValuesDefs(ddutil:getDDCodelistXmlUrl($schemaId), $result, $multiValueElems)
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
    let $ignoredElems := ("designationTypeCode")
    let $invalidElemKeys :=
        for $ignoredElem in $ignoredElems
        return fn:remove($invalidElemKeys, functx:if-empty(index-of($invalidElemKeys, $ignoredElem), 0))

    where fn:not(fn:empty($invalidElemKeys))
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
};

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
};

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
declare function xmlutil:buildCodelistValuesDefs($codeListXmlUrl as xs:string, $result as element(tr)*, $multiValueDelimiters as xs:string*)
as element(table){
    <table class="datatable" border="1">
        <thead>
            <tr>
                <th colspan="4">Code lists</th>
            </tr>
            <tr>
                <th>Field name</th>
                <th>Code list type</th>
                <th>Code list URL</th>
                <th>Multi-value delimiter</th>
            </tr>
        </thead>
        <tbody>
            {xmlutil:buildFixedValuesDefsRows($codeListXmlUrl, $result, $multiValueDelimiters)}
        </tbody>
    </table>
};

(:~
 : Build HTML table rows for displaying code list elements.
 : @param $codeListXmlUrl Url of DD codelists XML
 : @param $multiValueDelimiters list of multivalue elements and their delimiters
 : return HTML tr elements.
 :)
declare function xmlutil:buildFixedValuesDefsRows($codeListXmlUrl as xs:string, $result as element(tr)*, $multiValueDelimiters as xs:string*)
as element(tr)*
{

    let $codelists :=
    <codelistUrls>
        <url columnName="designatedAreaType" value="http://dd.eionet.europa.eu/vocabulary/cdda/designatedAreaTypeValue/" />
        <url columnName="cddaCountryCode" value="http://dd.eionet.europa.eu/vocabulary/cdda/cddaRegionCodeValue/" />
        <url columnName="cddaRegionCode" value="http://dd.eionet.europa.eu/vocabulary/cdda/cddaRegionCodeValue/" />
        <url columnName="designationTypeCode" value="http://dd.eionet.europa.eu/vocabulary/cdda/designationTypeCodeValue/" />
        <url columnName="iucnCategory" value="http://dd.eionet.europa.eu/vocabulary/cdda/IucnCategoryValue/" />
        <url columnName="majorEcosystemType" value="http://dd.eionet.europa.eu/vocabulary/cdda/majorEcosystemTypeValue/" />
        <url columnName="spatialDataDissemination" value="http://dd.eionet.europa.eu/vocabulary/cdda/spatialDataDisseminationValue/" />
        <url columnName="spatialResolutionCode" value="http://dd.eionet.europa.eu/vocabulary/cdda/spatialResolutionCodeValue/" />
        <url columnName="eionetChangeType" value="http://dd.eionet.europa.eu/fixedvalues/elem/92564" />
        <url columnName="siteEnded" value="http://dd.eionet.europa.eu/fixedvalues/elem/92568" />
    </codelistUrls>


    for $columnName at $pos in distinct-values(data($result//td/@element))
    let $valueList := fn:doc($codeListXmlUrl)//dd:value-list[@element=$columnName]
    let $dd_url := $codelists//url[@columnName=$columnName]/@value

    return
        <tr>
            <td>{ $columnName }</td>
            <td>{ if ($valueList/@fixed = 'true' or $valueList/@type = "fixed")
                then "Fixed"
                else if ($valueList/@type = "vocabulary")
                then "Vocabulary"
                else "Suggested" }
            </td>
            <td><a target="_blank" href="{ string($dd_url) }">
                { string($dd_url) }</a></td>
            <td>{ ddutil:getMultiValueDelim($multiValueDelimiters, $valueList/@element) }</td>
        </tr>
};
