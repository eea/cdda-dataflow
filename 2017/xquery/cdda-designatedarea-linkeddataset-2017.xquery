xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: CDDA 2017 - Site boundaries (Main module)
 :
 : Version:     $Id$
 : Created:     11 January 2018
 : Copyright:   European Environment Agency
 :)
(:~
 : XQuery script for CDDA 2017 - Site boundaries table.
 : The script checks the quality of reported data - mandatory values,
 : data types, code lists, duplicates.
 :
 : Reporting obligation: http://rod.eionet.europa.eu/obligations/32
 : XML Schema:  http://dd.eionet.europa.eu/GetSchema?id=TBL11022
 : XML Schema:  http://dd.eionet.europa.eu/GetSchema?id=TBL11023
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
declare namespace dd417="http://dd.eionet.europa.eu/namespace.jsp?ns_id=417";

(:
 : External global variable given as an external parameter by the QA service
 :)
 declare variable $source_url as xs:string external;
(:~ DD table ID :)
(: Designated Area :)
declare variable $xmlconv:SCHEMA_ID_DA as xs:string :=  $rules:DESIGNATEDAREA_SCHEMA;
(: Linked Dataset:)
declare variable $xmlconv:SCHEMA_ID_LD as xs:string :=  $rules:LINKEDDATASET_SCHEMA;
(:~ DD table elements namespace prefix :)
declare variable $xmlconv:ELEM_SCHEMA_NS_PREFIX_DA as xs:string :=  $rules:DESIGNATEDAREA_NS_PREFIX;
declare variable $xmlconv:ELEM_SCHEMA_NS_PREFIX_LD as xs:string :=  $rules:LINKEDDATASET_NS_PREFIX;
(:~ key element identifying row in the table, used in in the output key="" attribute:)
declare variable $xmlconv:KEY_ELEMENT_DA as xs:string := fn:concat($xmlconv:ELEM_SCHEMA_NS_PREFIX_DA, "cddaId");
declare variable $xmlconv:KEY_ELEMENT_LD as xs:string := fn:concat($xmlconv:ELEM_SCHEMA_NS_PREFIX_LD, "datasetId");
(:~ Elements with multiple values defined in DD  :)
declare variable $xmlconv:MULTIVALUE_ELEMS_DA as xs:string* := ddutil:getMultivalueElements($xmlconv:SCHEMA_ID_DA);
declare variable $xmlconv:MULTIVALUE_ELEMS_LD as xs:string* := ddutil:getMultivalueElements($xmlconv:SCHEMA_ID_LD);


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
as element(div)+
{
    let $ruleResults_DA := (
        xmlutil:executeMandatoryValuesCheck($url, $xmlconv:SCHEMA_ID_DA, $xmlconv:ELEM_SCHEMA_NS_PREFIX_DA, $xmlconv:KEY_ELEMENT_DA, "1.a", "DesignatedArea"),
        xmlutil:executeDuplicatesCheck($url, $xmlconv:SCHEMA_ID_DA, $xmlconv:ELEM_SCHEMA_NS_PREFIX_DA, $xmlconv:KEY_ELEMENT_DA, "2.a", ("cddaId"), true(), "DesignatedArea"),
        xmlutil:executeDataTypesCheck($url, $xmlconv:SCHEMA_ID_DA, $xmlconv:ELEM_SCHEMA_NS_PREFIX_DA, $xmlconv:KEY_ELEMENT_DA, "3.a", "DesignatedArea"),
        xmlutil:executeCodeListCheck($url, $xmlconv:SCHEMA_ID_DA, $xmlconv:ELEM_SCHEMA_NS_PREFIX_DA, $xmlconv:KEY_ELEMENT_DA, "4.a")
        )
    let $ruleResults_LD := (
        xmlutil:executeMandatoryValuesCheck($url, $xmlconv:SCHEMA_ID_LD, $xmlconv:ELEM_SCHEMA_NS_PREFIX_LD, $xmlconv:KEY_ELEMENT_LD, "1.b", "LinkedDataset"),
        xmlutil:executeDuplicatesCheck($url, $xmlconv:SCHEMA_ID_LD, $xmlconv:ELEM_SCHEMA_NS_PREFIX_LD, $xmlconv:KEY_ELEMENT_LD, "2.b", ("datasetId"), true(), "LinkedDataset"),
        xmlutil:executeDataTypesCheck($url, $xmlconv:SCHEMA_ID_LD, $xmlconv:ELEM_SCHEMA_NS_PREFIX_LD, $xmlconv:KEY_ELEMENT_LD, "3.b", "LinkedDataset")
        )

    return(
        uiutil:buildScriptResult($ruleResults_DA, ddutil:getDDTableUrl($xmlconv:SCHEMA_ID_DA), rules:getRules($xmlconv:SCHEMA_ID_DA)),
        uiutil:buildScriptResult($ruleResults_LD, ddutil:getDDTableUrl($xmlconv:SCHEMA_ID_LD), rules:getRules($xmlconv:SCHEMA_ID_LD))
    )

};

xmlconv:proceed($source_url)
