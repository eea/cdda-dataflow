xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: CDDA 2014 - Designations (Main module)
 :
 : Version:     $Id$
 : Created:     11 January 2018
 : Copyright:   European Environment Agency
 :)
(:~
 : XQuery script for CDDA 2017 - Designations table.
 : The script checks the quality of reported data - mandatory values,
 : data types, code lists, duplicates.
 :
 : Reporting obligation: http://rod.eionet.europa.eu/obligations/32
 : XML Schema:  http://dd.eionet.europa.eu/GetSchema?id=TBL9121
 :
 :)
(: Data Dictionary utility methods:)
import module namespace ddutil = "http://converters.eionet.europa.eu/ddutil" at "cdda-dd-util.xquery";
(: Common utility methods :)
import module namespace cutil = "http://converters.eionet.europa.eu/cutil" at "cdda-common-util.xquery";
(: UI utility methods for build HTML formatted QA result:)
import module namespace uiutil = "http://converters.eionet.europa.eu/ui" at "cdda-ui-util-2017.xquery";
(: Dataset specific utility methods for executing QA scripts:)
import module namespace xmlutil = "http://converters.eionet.europa.eu/cdda/xmlutil" at "cdda-util-2017.xquery";
(: Dataset rule definitions and utility methods:)
import module namespace rules = "http://converters.eionet.europa.eu/cdda/rules" at "cdda-rules-2017.xquery";
declare namespace xmlconv="http://converters.eionet.europa.eu/cdda/sites";
declare namespace dd11="http://dd.eionet.europa.eu/namespace.jsp?ns_id=11";
declare namespace dd48="http://dd.eionet.europa.eu/namespace.jsp?ns_id=48";

(:
 : External global variable given as an external parameter by the QA service
 :)
 declare variable $source_url as xs:string external;

(:
 TEST files:
 declare variable $source_url as xs:string external;
 declare variable $source_url := "../test/cdda_designations-2014.xml";
 :)
(:~ DD table ID :)
declare variable $xmlconv:SCHEMA_ID as xs:string :=  $rules:DESIG_SCHEMA;
(:~ DD table elements namespace prefix :)
declare variable $xmlconv:ELEM_SCHEMA_NS_PREFIX as xs:string :=  $rules:DESIG_NS_PREFIX;
(:~ key element identifying row in the table, used in in the output key="" attribute:)
declare variable $xmlconv:KEY_ELEMENT as xs:string := fn:concat($xmlconv:ELEM_SCHEMA_NS_PREFIX, "DESIG_ABBR");
(:~ Elements with multiple values defined in DD  :)
declare variable $xmlconv:MULTIVALUE_ELEMS as xs:string* := ddutil:getMultivalueElements($xmlconv:SCHEMA_ID);


(:===================================================================
 :              MODULE ENTRY POINT
 :===================================================================
 :)
(:~
 : The main method for this module. Calls different QA methods and returns the HTML snippet with QA results.
 : @param $uri URL of XML to be checked.
 : @return HTML code snippet inside <div class="feedbacktext"> element.
 :)
declare function xmlconv:proceed($url as xs:string)
as element(div)
{
    let $ruleResults := (
        xmlutil:executeMandatoryValuesCheck($url, $xmlconv:SCHEMA_ID, $xmlconv:ELEM_SCHEMA_NS_PREFIX, $xmlconv:KEY_ELEMENT, "1")
        , xmlutil:executeDuplicatesCheck($url, $xmlconv:SCHEMA_ID, $xmlconv:ELEM_SCHEMA_NS_PREFIX, $xmlconv:KEY_ELEMENT, "2",
            ("ISO3", "DESIG_ABBR"), false())
        , xmlutil:executeDataTypesCheck($url, $xmlconv:SCHEMA_ID, $xmlconv:ELEM_SCHEMA_NS_PREFIX, $xmlconv:KEY_ELEMENT, "3")
        , xmlutil:executeCountryCodeCheck($url, $xmlconv:SCHEMA_ID, $xmlconv:ELEM_SCHEMA_NS_PREFIX, $xmlconv:KEY_ELEMENT, "4")
        , xmlutil:executeCodeListCheck($url, $xmlconv:SCHEMA_ID, $xmlconv:ELEM_SCHEMA_NS_PREFIX, $xmlconv:KEY_ELEMENT, "5")
        )

    return
        uiutil:buildScriptResult($ruleResults, ddutil:getDDTableUrl($xmlconv:SCHEMA_ID), rules:getRules($xmlconv:SCHEMA_ID))

};

xmlconv:proceed($source_url)
