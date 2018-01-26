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
(: External global variable given as an external parameter by the QA service  :)
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



(: Feedback status: the returned string will be used as feedback status value :)
declare function xmlconv:feedbackStatus($toc as element()*) as xs:string
{
    let $span := $toc//span[@id='feedbackStatusTmp']
    return
        if (exists($span[contains(@class, 'BLOCKER')])) then
            "BLOCKER"
        else if (exists($span[contains(@class, 'ERROR')])) then
            "ERROR"
        else if (exists($span[contains(@class, 'WARNING')])) then
                "WARNING"
        else if (exists($span[contains(@class, 'INFO')])) then
                "INFO"
            else
                "OK"
};

declare function xmlconv:buildSummary($ruleResults as element(div)*, $rules as element(rules))
as element(div)
{
    let $resultErrors := uiutil:getResultErrors($ruleResults)
    let $resultCodes := uiutil:getResultCodes($ruleResults)
    let $resultNrOfRecordsDetected := $ruleResults//p[@id]
    return
        <div>{
            uiutil:buildTableOfContents($rules//rule, $resultCodes, $resultErrors, "", $resultNrOfRecordsDetected)
        }</div>
};

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
    let $containerDA := "DesignatedArea"
    let $ruleResults_DA := (
        xmlutil:executeMandatoryValuesCheck($url, $xmlconv:SCHEMA_ID_DA, $xmlconv:ELEM_SCHEMA_NS_PREFIX_DA, $xmlconv:KEY_ELEMENT_DA, "1a", $containerDA),
        xmlutil:executeDuplicatesCheck($url, $xmlconv:SCHEMA_ID_DA, $xmlconv:ELEM_SCHEMA_NS_PREFIX_DA, $xmlconv:KEY_ELEMENT_DA, "2a", ("cddaId"), true(), $containerDA),
        xmlutil:executeDataTypesCheck($url, $xmlconv:SCHEMA_ID_DA, $xmlconv:ELEM_SCHEMA_NS_PREFIX_DA, $xmlconv:KEY_ELEMENT_DA, "3a", $containerDA),
        xmlutil:executeCodeListCheck($url, $xmlconv:SCHEMA_ID_DA, $xmlconv:ELEM_SCHEMA_NS_PREFIX_DA, $xmlconv:KEY_ELEMENT_DA, "4a", $containerDA)
        )
    let $containerLD := "LinkedDataset"
    let $ruleResults_LD := (
        xmlutil:executeMandatoryValuesCheck($url, $xmlconv:SCHEMA_ID_LD, $xmlconv:ELEM_SCHEMA_NS_PREFIX_LD, $xmlconv:KEY_ELEMENT_LD, "1b", $containerLD),
        xmlutil:executeDuplicatesCheck($url, $xmlconv:SCHEMA_ID_LD, $xmlconv:ELEM_SCHEMA_NS_PREFIX_LD, $xmlconv:KEY_ELEMENT_LD, "2b", ("datasetId"), true(), $containerLD),
        xmlutil:executeDataTypesCheck($url, $xmlconv:SCHEMA_ID_LD, $xmlconv:ELEM_SCHEMA_NS_PREFIX_LD, $xmlconv:KEY_ELEMENT_LD, "3b", $containerLD)
        )

    let $resultDA := uiutil:buildScriptResult($ruleResults_DA, ddutil:getDDTableUrl($xmlconv:SCHEMA_ID_DA), rules:getRules($xmlconv:SCHEMA_ID_DA))
    let $resultDAs := xmlconv:buildSummary($ruleResults_DA, rules:getRules($xmlconv:SCHEMA_ID_DA))
    let $resultLD := uiutil:buildScriptResult($ruleResults_LD, ddutil:getDDTableUrl($xmlconv:SCHEMA_ID_LD), rules:getRules($xmlconv:SCHEMA_ID_LD))
    let $resultLDs := xmlconv:buildSummary($ruleResults_LD, rules:getRules($xmlconv:SCHEMA_ID_LD))
    let $errorLevel := xmlconv:feedbackStatus(($resultDA, $resultLD))
    let $resultTableOfContents :=
        <div>
        <h1>Common Database on Designated Areas (CDDA)</h1>
        <ul>{
             <li><strong>Designated area</strong>&#32;&#32;{  uiutil:getRuleResultBox('a',concat('a-',lower-case(xmlconv:feedbackStatus(($resultDA)))), 0) }
                 {$resultDAs}</li>,
             <br/>,
             <li><strong>Linked dataset</strong>&#32;&#32;{  uiutil:getRuleResultBox('b',concat('b-',lower-case(xmlconv:feedbackStatus(($resultLD)))), 0) }
                 {$resultLDs}</li>
        }</ul>
        </div>
    let $feedbackMessage :=
        if ($errorLevel = 'OK') then
            "All tests passed without errors or warnings"
        else
            normalize-space(string-join(distinct-values($resultTableOfContents//span[@id="feedbackStatusTmp"]), ' || '))

    return(
        <div>
            <span id="feedbackStatus" class="{ $errorLevel }" style="display:none">{ $feedbackMessage }</span>
            {$resultTableOfContents}
            {$resultDA}
            {$resultLD}
        </div>
    )

};

xmlconv:proceed($source_url)

