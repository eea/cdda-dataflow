xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: CDDA 2017 - UI methods (Library module)
 :
 : Version:     $Id$
 : Created:     11 January 2018
 : Copyright:   European Environment Agency
 :)
(:~
 : UI utility methods for build HTML formatted QA result.
 : Reporting obligation: http://rod.eionet.europa.eu/obligations/32
 :
 :)
module namespace uiutil = "http://converters.eionet.europa.eu/ui";
(: Common utility methods :)
import module namespace cutil = "http://converters.eionet.europa.eu/cutil" at "cdda-common-util.xquery";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";

(:~ Constant for error level messages. :)
declare variable $uiutil:ERROR_LEVEL as xs:integer :=  0;
(:~ Constant for warning level messages. :)
declare variable $uiutil:WARNING_LEVEL as xs:integer :=  1;
declare variable $uiutil:BLOCKER_LEVEL as xs:integer :=  2;
(:~ Error flag token placed in invalid rule results. :)
declare variable $uiutil:ERROR_FLAG as xs:string :=  "ERRORFLAG";
declare variable $uiutil:BLOCKER_FLAG as xs:string :=  "BLOCKERFLAG";
(:~ Warning flag token placed in invalid rule results. :)
declare variable $uiutil:WARNING_FLAG as xs:string :=  "WARNINGFLAG";
(:~ Message displayed for missig values. :)
declare variable $uiutil:MISSING_VALUE_LABEL as xs:string :=  "-empty-";
(:~ Maximum length of string value displayed in the result table :)
declare variable $uiutil:MAX_VALUE_LENGTH as xs:integer :=  100;

declare variable $uiutil:RESULT_TYPE_MINIMAL := "minimal";
declare variable $uiutil:RESULT_TYPE_TABLE := "table";
declare variable $uiutil:RESULT_TYPE_TABLE_CODES := "table-codes";
(:
 : ======================================================================
 :              UI HELPER methods for building QA results HTML
 : ======================================================================
 :)

declare function uiutil:buildScriptResult($ruleResults as element(div)*, $schemaUrl as xs:string, $rules as element(rules))
as element(div)
{
    let $resultErrors := uiutil:getResultErrors($ruleResults)
    let $resultCodes := uiutil:getResultCodes($ruleResults)
    return
    <div class="feedbacktext">{
        uiutil:buildScriptHeader($rules)
        }{ uiutil:buildTableOfContents($rules//rule, $resultCodes, $resultErrors)
        }{ if ($schemaUrl = "") then "" else uiutil:buildLinkToDD($schemaUrl)
        }{
        for $ruleResult in $ruleResults
        return
            $ruleResult
    }</div>
};

declare function uiutil:buildScriptResultFullHtml($ruleResults as element(div)*, $schemaUrl as xs:string, $rules as element(rules))
as element(html)
{
  <html>
    <head>
        <meta content="text/html; charset=UTF-8" http-equiv="Content-Type"/>
        <link rel="stylesheet" type="text/css" href="http://www.eionet.europa.eu/styles/eionet2007/print.css" media="print" />
        <link rel="stylesheet" type="text/css" href="http://www.eionet.europa.eu/styles/eionet2007/handheld.css" media="handheld" />
        <link rel="stylesheet" type="text/css" href="http://www.eionet.europa.eu/styles/eionet2007/screen.css" media="screen" />
    </head>
    <body>
        {uiutil:buildScriptResult($ruleResults, $schemaUrl, $rules)}
    </body>
  </html>
};

 (:~
 : @return QA rule results in HTML format.
 :)
declare function uiutil:buildCommonRuleResult($result as element(tr)*, $ruleDef as element(rule), $ruleElementNames as xs:string*)
as element(div)
{
    uiutil:buildRuleResult($result, $ruleDef, $ruleElementNames, <div/>, $uiutil:RESULT_TYPE_MINIMAL)
};

declare function uiutil:buildRuleResult($result as element(tr)*, $ruleDef as element(rule), $ruleElementNames as xs:string*,
        $additionalInfo as element(div), $resultTableType as xs:string)
as element(div)
{
let $ruleCode := $ruleDef/@code
let $errorLevel := $ruleDef/errorLevel
let $exceptionLevel :=
    let $flags := distinct-values($result//span[@style = "display:none"])
    return if(count($flags) = 1)
        then
            $flags
        else
            "BLOCKERFLAG"

return
    if (empty($result)) then
        uiutil:buildSuccessHeader($ruleDef)
    else
        <div>{
            if($errorLevel = "2")
            then
                if($exceptionLevel = "BLOCKERFLAG")
                then
                    uiutil:buildBlockerHeader($ruleDef, $ruleDef/message)
                else if($exceptionLevel = "WARNINGFLAG" and $ruleCode != "1a")
                    then
                        uiutil:buildWarningHeader($ruleDef, $ruleDef/message)
                else
                    uiutil:buildFailedHeader($ruleDef, "")
            else
                uiutil:buildFailedHeader($ruleDef, "")
            }
            {
                uiutil:getResultInfoTable($result, $ruleCode, $resultTableType)
            }
            <div id="detailDiv-{$ruleCode}" style="display: none;">
                <table border="1" class="datatable" error="{ uiutil:getRuleMessage($ruleDef) }">{
                    uiutil:buildTableHeaderRow($ruleElementNames)
                    }{ $result
                }</table>
             </div>{
             $additionalInfo
        }</div>

};

declare function uiutil:buildScriptHeader($rules as element(rules))
as element(h2)
{
    let $ruleCount := fn:count($rules//rule[contains(@code, ".") = false()])
    return
        <h2>The following { if ($ruleCount > 1) then $ruleCount else "" } quality test{ if ($ruleCount > 1) then "s" else "" } were made against this table - {
        fn:data($rules/@title) }</h2>
};

(:~
 : Build link to DD.
 : @param $schemaId DD table ID
 : @return
 :)
declare function uiutil:buildLinkToDD($schemaUrl as xs:string)
as element(p)
{
    <p>View detailed data definitions in <a href="{ $schemaUrl }">Data Dictionary</a></p>
};

(:~
 : Function builds HTML fragemnt for displaying successful rule result header.
 : @param $rule Rule element defined in rules XML.
 : @return HTML fragment.
 :)
declare function uiutil:buildSuccessHeader($rule as element(rule))
as element(div)
{
    <div result="{ uiutil:getResultCode($rule/@code , "ok") }">{
        uiutil:buildTitle($rule)}{
        uiutil:buildDescr($rule)
        }<div style="color:green">OK - the test was passed successfully.</div>
    </div>
};

(:~
 : Function builds HTML fragemnt for displaying successful sub rule result header.
 : @param $rule Rule element defined in rules XML.
 : @return HTML fragment.
 :)
declare function uiutil:buildSuccessSubHeader($rule as element(rule))
as element(div)
{
    <div>
        <h3>{
        concat($rule/@code, " ", $rule/title)
        }</h3>
        <p>{ fn:data($rule/message) }</p>
        <div style="color:green">OK - the test was passed successfully.</div>
    </div>
};

(:~
 : Function builds HTML fragemnt for displaying failed sub rule result header.
 : @param $rule Rule element defined in rules XML.
 : @return HTML fragment.
 :)
declare function uiutil:buildFailedSubHeader($rule as element(rule))
as element(div)
{
    <div>
        <h3>{
        concat($rule/@code, " ", $rule/title)
        }</h3>
        <p>{ fn:data($rule/message) }</p>{
        uiutil:getFailedMessage("", "")
    }</div>
};

(:~
 : Function builds HTML fragemnt for displaying rule results header with warnings.
 : @param $rule Rule element defined in rules XML.
 : @param $blockerMessage Blocker message displayed in the header.
 : @return HTML fragment
 :)
declare function uiutil:buildBlockerHeader($rule as element(rule), $blockerMessage as xs:string)
as element(div)
{
    <div result="{ uiutil:getResultCode($rule/@code , "blocker") }">{
        uiutil:buildTitle($rule) }{
        uiutil:buildDescr($rule)
        }<div style="color:red">BLOCKER - { $blockerMessage }</div>
    </div>
};

(:~
 : Function builds HTML fragemnt for displaying failed rule result header.
 : @param $rule Rule element defined in rules XML.
 : @param $errMessage Error message displayed in the header.
 : @return HTML fragment
 :)
declare function uiutil:buildFailedHeader($rule as element(rule), $errMessage as xs:string)
as element(div)
{
    <div result="{ uiutil:getResultCode($rule/@code , "error") }">{
        uiutil:buildTitle($rule) }{
        uiutil:buildDescr($rule) }{
        uiutil:getFailedMessage(fn:string($rule/message),$errMessage)
    }</div>
};

(:~
 : Function builds HTML fragemnt for displaying rule results header with warnings.
 : @param $rule Rule element defined in rules XML.
 : @param $warnMessage Warning message displayed in the header.
 : @return HTML fragment
 :)
declare function uiutil:buildWarningHeader($rule as element(rule), $warnMessage as xs:string)
as element(div)
{
    <div result="{ uiutil:getResultCode($rule/@code , "warning") }">{
        uiutil:buildTitle($rule) }{
        uiutil:buildDescr($rule)
        }<div style="color:orange">WARNING - { $warnMessage }</div>
    </div>
};

(:~
 : Function builds HTML fragemnt for displaying rule results header with info.
 : @param $rule Rule element defined in rules XML.
 : @param $infoMessage Info message displayed in the header.
 : @param $textColor Text color for info message.
 : @return HTML fragment
 :)
declare function uiutil:buildInfoHeader($rule as element(rule), $infoMessage as xs:string, $textColor as xs:string)
as element(div)
{
    <div result="{ uiutil:getResultCode($rule/@code , "skipped") }">{
        uiutil:buildTitle($rule) }{
        uiutil:buildDescr($rule)
        }<div style="color:{$textColor}">{ $infoMessage }</div>
    </div>
};

(:~
 : Build error TD, if the checked element value is invalid. The returned td element is displayed in the tabel of rule results.
 : This is the entry function for building result table cells. If the checked element value is valid, then just return the value between td tags.
 : Otherwise the invalid value is wrapped with error message.
 : @param $checkedRow Element displayed in the table cell.
 : @param $elementName Element name.
 : @param $rule Rule element defined in rules XML.
 : @param $showMissing True if missing values showed be displayed.
 : @param $errLevel error level (0 - ERROR, 1 - WARNING)
 : @param $isInvalid True, if the checked element in invalid.
 : @param $valueDelimiter Separator character for delimiting multivalue element values.
 : @return HTML fragment.
 :)
declare function uiutil:buildTD($checkedRow as element(), $elementName as xs:string, $errMess as xs:string,
    $showMissing as xs:boolean, $errLevel as xs:integer, $isInvalid as xs:boolean*, $valueDelimiter as xs:string, $ruleCode as xs:string)
as element(td)
{
    let $isMultivalueElem := $valueDelimiter != ""
    let $value :=  if ($isMultivalueElem) then
                        string-join($checkedRow//child::*[local-name() = $elementName], $valueDelimiter)
                   else
                        string($checkedRow//child::*[local-name() = $elementName])
    let $isValid := empty(index-of($isInvalid, fn:true()))
    let $valueForDisplay := if (not($isValid)) then uiutil:getElementValueForDisplay($value, $showMissing, $isInvalid, $errLevel, $valueDelimiter) else ""
    let $value := if (string-length($value) > $uiutil:MAX_VALUE_LENGTH) then concat(fn:substring($value, 1, $uiutil:MAX_VALUE_LENGTH), " ...") else $value
    return
        if ($isValid) then
            <td>{ $value }</td>
        else
            uiutil:getErrorTD($valueForDisplay, $errMess, $showMissing, $elementName, $errLevel, $isMultivalueElem, $ruleCode)
};

(:~
 : Function builds HTML td element with invalid value and error codes
 : @param $errValue Element value.
 : @param $errMessage Error message displayed for user.
 : @param $showMissing True if missing values showed be displayed.
 : @param $elementName XML element name.
 : @param $errLevel Error level @see $uiutil:ERROR_LEVEL
 : @return HTML table td element
 :)
declare function uiutil:getErrorTD($errValue as element(span)*,  $errMessage as xs:string,
    $showMissing as xs:boolean, $elementName as xs:string, $errLevel as xs:integer, $isMultiValueElem as xs:boolean, $ruleCode as xs:string)
as element(td)
{
    let $errColor := if ($isMultiValueElem) then "" else fn:concat("color:", uiutil:getErrorColor($errLevel))
    return
        <td title="{ $errMessage }" element="{ $elementName }" errorCode="{ $ruleCode }" style="{ $errColor }">{
            $errValue
        }<span style="display:none">{ uiutil:getErrorFlagByLevel($errLevel) }</span></td>
};
declare function uiutil:getElementValue($row as element(), $element as xs:string, $delimiter as xs:string)
as xs:string
{
    fn:string-join(uiutil:getElementValues($row/*[name()=$element]), $delimiter)
};

declare function uiutil:getElementValueSorted($row as element(), $element as xs:string, $delimiter as xs:string)
as xs:string
{
    string-join(cutil:sort(uiutil:getElementValues($row/*[name()=$element])), $delimiter)
};

declare function uiutil:getElementValues($elements as element())
as xs:string*
{
    for $elem in $elements
    where not(cutil:isEmpty($elem))
    return
            normalize-space(string($elem))
};

(:~
 : Build the HTML span element for displaying XML element value. The value can be multivalue element
 : and some of the values can be valid and the others could be invalid. Invalid values should be colored red.
 : @param $errValue Invalid value from XML.
 : @param $showMissing True if missing values showed be displayed.
 : @param $isInvalid List of boolean values. True, if the checked element in invalid.
 : @param $errLevel error level (0 - ERROR, 1 - WARNING)
 : @param $valueDelimiter Separator character for delimiting multivalue element values.
 : @return HTML span element.
 :)
declare function uiutil:getElementValueForDisplay($errValue as xs:string, $showMissing as xs:boolean, $isInvalid as xs:boolean*,
    $errLevel as xs:integer, $valueDelimiter as xs:string)
as element(span)*
{
    let $isMultivalueElem := $valueDelimiter != ""
    let $errValue :=
        if ($showMissing = fn:true() and ((not($isMultivalueElem) and cutil:isEmpty($errValue))
            or ($isMultivalueElem and cutil:isEmpty(fn:replace($errValue, $valueDelimiter, ""))))) then
            $uiutil:MISSING_VALUE_LABEL
        else
            $errValue

    let $multiValues := if ($isMultivalueElem) then fn:tokenize($errValue, $valueDelimiter) else ($errValue)

    for $value at $pos in $multiValues
    let $isValid :=
        if (count($isInvalid)>=$pos) then
            not($isInvalid[$pos ])
        else if (count($isInvalid)=1) then
            not($isInvalid[1])
        else
            fn:true()
    let $color := if($isValid) then "" else fn:concat("color:", uiutil:getErrorColor($errLevel))
    let $showDelimiter := if ($isMultivalueElem and $pos < count($multiValues)) then fn:true() else fn:false()
    let $valueForDisplay := if (string-length($value) > $uiutil:MAX_VALUE_LENGTH) then concat(fn:substring($value, 1, $uiutil:MAX_VALUE_LENGTH), " ...") else $value

    return
            (<span style="{ $color }">{ normalize-space($valueForDisplay) }</span>,
            if ($showDelimiter) then
                <span>{ $valueDelimiter }</span>
            else
                ()
            )
};

(:~
 : Return the color of error message.
 : @param $errLevel error level (0 - ERROR, 1 - WARNING)
 : @rteturn color name
 :)
declare function uiutil:getErrorColor($errLevel as xs:integer)
as xs:string
{
    if ($errLevel = $uiutil:WARNING_LEVEL) then
        "orange"
    else
        "red"
};

(:~
 : Return the flag name of error message.
 : @param $errLevel error level (0 - ERROR, 1 - WARNING)
 : @rteturn flag name
 :)
declare function uiutil:getErrorFlagByLevel($errLevel as xs:integer)
as xs:string
{
    if($errLevel = $uiutil:WARNING_LEVEL) then
        $uiutil:WARNING_FLAG
    else if($errLevel = $uiutil:BLOCKER_LEVEL) then
        $uiutil:BLOCKER_FLAG
    else
        $uiutil:ERROR_FLAG
};

(:~
 : Build HTML title element
 : @param $rule Rule element defined in rules XML.
 : @return HTML fragment
 :)
declare function uiutil:buildTitle($rule as element(rule))
as element(h2)
{
    <h2><a name="{ fn:string($rule/@code) }">{ fn:string($rule/@code) }.</a>&#32;{ fn:string($rule/title) }</h2>
};

(:~
 : Build HTML descritoption element
 : @param $rule Rule element defined in rules XML.
 : @return HTML fragment
 :)
declare function uiutil:buildDescr($rule as element(rule))
as element(p)
{
    <p>{
        $rule/descr/child::node()
    }{
        if (count($rule/additionalDescr) > 0) then
            <ul>{
                for $p in $rule/additionalDescr
                return
                    <li>{ $p }</li>
            }</ul>
        else
            ()
    }</p>
};

(:~
 : Get red colored error message displayed for invalid value. Concats 2 messages if both provided.
 : @param $errMessage Error message.
 : @param $errMessage2 Optional error message. To be concatenated to the first message.
 : @return HTML fragment
 :)
declare function uiutil:getFailedMessage($errMessage as xs:string, $errMessage2 as xs:string)
as element(div)
{
    let $mess := "ERROR - the test was not passed."
    let $fullMessage :=
        if (cutil:isEmpty($errMessage)) then
            concat($mess, " ", $errMessage2)
        else
            concat($mess, " ", $errMessage, " ", $errMessage2)
    return
        <div style="color:red">{ $fullMessage }</div>
};

(:~
 : Get rule message description from the XML rule element.
 : @param $rule Rule element defined in rules XML.
 : @return String message.
 :)
declare function uiutil:getRuleMessage($rule as element(rule))
as xs:string
{
    fn:string($rule/message)
};

(:~
 : Builds the HTML table header row with all the required element names.
 : @param $ruleElementNames List of element names.
 : @return HTML tr element.
 :)
declare function uiutil:buildTableHeaderRow($ruleElementNames as xs:string*)
as element(tr)
{
    <tr align="center">
        <th>Row</th>{
            for $n in $ruleElementNames
                return
                    <th>{$n}</th>
    }</tr>
};

(:~
 : Build HTML title and table with invalid rows for sub-rule.
 : @param $ruleDef Rule code in rules XML.
 : @param $result HTML table tr elements with invalid values.
 : @param $ruleElements List of XML elements used in this rule
 : @return HTML div element.
 :)
declare function uiutil:buildSubRuleFailedResult($ruleDef as element(rule), $result as element(tr)*, $ruleElements as xs:string*)
as element(div){
    <div>{
        uiutil:buildFailedSubHeader($ruleDef)
        }<table border="1" class="datatable" error="{ uiutil:getRuleMessage($ruleDef) }">{
            uiutil:buildTableHeaderRow($ruleElements)
            }{$result
        }</table>
    </div>
};

(:~ Build HTML list containing links to QA rules. Display result message at the end of link.
 : @param $rules List of rule elements from rules XML.
 : @param $results List of rule result codes.
 : @return HTML list of rule headings.
 :)
declare function uiutil:buildTableOfContents($rules as element(rule)*, $results as xs:string*, $resultErrors as element(td)*)
as element(div) {
    uiutil:buildTableOfContents($rules, $results, $resultErrors, "display:none;")
};

declare function uiutil:buildTableOfContents($rules as element(rule)*, $results as xs:string*, $resultErrors as element(td)*, $style as xs:string)
as element(div)
{
    let $ruleCount := fn:count($rules[contains(@code, ".") = false()])           
    let $resultTableOfContents :=
        <ul style="{$style}">{
            for $rule in $rules[contains(@code, ".") = false()]
            let $countErrors := count($resultErrors[@errorCode = data($rule/@code)])
            return
                <li><a href="#{ fn:data($rule/@code) }">{ if ($ruleCount > 1) then fn:concat(fn:data($rule/@code), ".&#32;") else "" }{ fn:data($rule/title) }</a>&#32;&#32;{  uiutil:getRuleResultBox(fn:data($rule/@code), $results, $countErrors) }</li>
        }</ul>
    let $errorLevel := uiutil:feedbackStatus($resultTableOfContents)
    let $feedbackMessage :=
        if ($errorLevel = 'OK') then
            "All tests passed without errors or warnings"
        else
            normalize-space(string-join($resultTableOfContents//li[contains(span, $errorLevel)], ' || '))
    return
        <div><span id="feedbackStatusTmp" class="{ $errorLevel }" style="display:none">{ $feedbackMessage }</span>{ $resultTableOfContents }</div>
};

(:~
 : Create rule result message displayed in the list of rules at the end of each rule.
 : @param $errorCode Rule code.
 : @param $results Rule results codes ("1-ok")
 : return HTML containing rule result message
 :)
declare function uiutil:getRuleResultBox($errorCode as xs:string, $results as xs:string*, $countErrors as xs:integer)
as element(span)*{

    let $errCountStr := if ($countErrors > 0 ) then concat(" (", $countErrors, ") ") else ""
    return
    for $result in $results
    let $resultCode := fn:substring-after($result, "-")
    where substring-before($result, "-") = $errorCode
    return
        if($resultCode = "ok") then
            <span style="background-color:green;font-size:0.8em;color:white;padding-left:9px;padding-right:9px;text-align:center">OK</span>
        else if($resultCode = "blocker") then
            <span style="background-color:red;font-size:0.8em;color:white;padding-left:3px;padding-right:3px;text-align:center">BLOCKER{ $errCountStr }</span>
        else if($resultCode = "error") then
            <span style="background-color:red;font-size:0.8em;color:white;padding-left:3px;padding-right:3px;text-align:center">ERROR{ $errCountStr }</span>
        else if($resultCode = "warning") then
            <span style="background-color:orange;font-size:0.8em;color:white;padding-left:3px;padding-right:3px;text-align:center">WARNING{ $errCountStr }</span>
        else if($resultCode = "skipped") then
            <span style="background-color:brown;font-size:0.8em;color:white;padding-left:3px;padding-right:3px;text-align:center">SKIPPED</span>
        else
            <span/>

};

(:~
 : Build rule results code containg rule code and result message eg.: "1-ok" or "2-error"
 : @param $errorCode Rule code.
 : @param $result Result code: error, ok, warning
 : @return Rule result code.
 :)
declare function uiutil:getResultCode($errorCode as xs:string, $result as xs:string)
as xs:string
{
   fn:concat($errorCode, "-", $result)
};

(:~
 : Return rule results from span result attribute.
 : @param $results List of rule results as HTML fragments starting with span element.
 : @return List of rule results.
 :)
declare function uiutil:getResultCodes($results as element(div)*)
as xs:string*
{
    for $result in $results
    return
        if (fn:string-length($result/@result) > 0) then
            fn:string($result/@result)
        else if (fn:string-length($result/div/@result) > 0) then
            fn:string($result/div/@result)
        else
            ()
};

(:~
 : Return rule results from span result attribute.
 : @param $results List of rule results as HTML fragments starting with span element.
 : @return List of rule results.
 :)
declare function uiutil:getResultErrors($results as element(div)*)
as element(td)*
{
    $results//td[string-length(@errorCode) > 0]
};

(:~
 : Build HTML table for logical rules errros.
 : @param $ruleDefs List of rule elements
 : @return HTML table element.
 :)
declare function uiutil:buildRulesTable($ruleDefs as element(rule)*)
as element(table)
{
    <table class="datatable" border="1">
        <tr>
            <th>Code</th>
            <th style="width:300px">Rule violated</th>
            {
            if(count($ruleDefs//*[name()="message2"]) > 0) then
                <th>Description</th>
            else
                <th style="display:none"/>
            }
        </tr>{
            for $ruleDef in $ruleDefs
            let $value :=  fn:substring-after($ruleDef/@code, ".")
            return
                <tr>
                    <td>{ fn:data($value) }</td>
                    <td>{ fn:data($ruleDef/message) }</td>
                    {
                    if(count($ruleDefs//*[name()="message2"]) > 0) then
                        <td>{ fn:data($ruleDef/message2) }</td>
                    else
                        <td style="display:none"/>
                    }
                </tr>
    }</table>
};

declare function uiutil:buttonStyle(){

    let $buttonStyle :=
            'background-image: -moz-linear-gradient(center bottom , #CFCFCF 16%, #FCFCFC 79%);
            border: 1px solid #000000;
            border-radius: 5px 5px 5px 5px;
            color: #000000;
            padding: 2px 5px;
            text-decoration: none;'
    return
        $buttonStyle
};

declare function uiutil:showAndHideRecordsButton($ruleCode as xs:string){
    let $button :=
            <a id="buttonId-{$ruleCode}"
            style="{uiutil:buttonStyle()}"
             href="javascript:void(0)"
             onclick="javascript:toggle('emptyDiv-{$ruleCode}','detailDiv-{$ruleCode}','buttonId-{$ruleCode}','tableCheckboxes-{$ruleCode}','detailDiv-{$ruleCode}','checkBoxes-{$ruleCode}');" >
                Show records
             </a>
    return
        $button

};

(:==================================================================:)
(: Prints out info table rows  :)
(:==================================================================:)
declare function uiutil:getResultInfoTableTR($mandatoryResult as element(tr)*, $ruleCode as xs:string, $resultType as xs:string){

    for $columnName at $pos in distinct-values(data($mandatoryResult//td/@element))
    let $countErrors := count($mandatoryResult//td[@element = $columnName])
    let $invalidCodes :=
        if ($resultType = $uiutil:RESULT_TYPE_TABLE_CODES) then
            string-join(distinct-values($mandatoryResult//td[@element = $columnName]/span[@style='color:red' or @style='color:orange']/text()), ", ")
        else
            ()
    return
        if($countErrors > 0) then
            <tr>
                <td>
                    <input class="checkBoxes-{$ruleCode}" type="checkbox" name="checkbox" value="{$columnName}" id="chk{concat($ruleCode, "-", $pos)}"
                    onclick="javascript:checkboxToggle('tableCheckboxes-{$ruleCode}','detailDiv-{$ruleCode}','checkBoxes-{$ruleCode}');" />
                </td>

                <td><label for="chk{concat($ruleCode, "-", $pos)}">{cutil:getElemNameWithoutNs($columnName)}</label></td>
                <td>{$countErrors}</td>{
                if ($resultType = $uiutil:RESULT_TYPE_TABLE_CODES) then
                    <td>{$invalidCodes}</td>
                else
                    ()
                }
            </tr>
        else
            ()

};

(:==================================================================:)
(: Prints out info table with javascript :)
(:==================================================================:)
declare function uiutil:getResultInfoTable($mandatoryResult as element(tr)*, $ruleCode as xs:string)
as element(div){
    uiutil:getResultInfoTable($mandatoryResult, $ruleCode, $uiutil:RESULT_TYPE_MINIMAL)
};

declare function uiutil:getResultInfoTable($mandatoryResult as element(tr)*, $ruleCode as xs:string, $type as xs:string)
as element(div){

       let $countInvalidRecords := count($mandatoryResult)
       let $resultText := <p>{$countInvalidRecords} record{if ($countInvalidRecords > 1) then "s" else ""} detected.</p>

       let $colHeaderText :=
            if ($countInvalidRecords > 0 and count($mandatoryResult[1]/td)>1 and exists($mandatoryResult[1]/td[2]/@title)
                and contains(lower-case($mandatoryResult[1]/td[2]/@title), "mandatory values test")) then
                "Number of records with missing values"
            else
                "Number of records detected"
       let $resultTable :=
            if ($type = $uiutil:RESULT_TYPE_TABLE) then
                <table border="1" id="tableCheckboxes-{$ruleCode}" class="datatable">
                        <tr>
                            <th></th>
                            <th>Element name</th>
                            <th>{$colHeaderText}</th>
                        </tr>
                        {uiutil:getResultInfoTableTR($mandatoryResult, $ruleCode, $type)}
                   </table>
            else if ($type = $uiutil:RESULT_TYPE_TABLE_CODES) then
                <table border="1" id="tableCheckboxes-{$ruleCode}" class="datatable">
                        <tr>
                            <th></th>
                            <th>Element name</th>
                            <th>Number of records with incorrect codes</th>
                            <th>List of incorrect codes</th>
                        </tr>
                        {uiutil:getResultInfoTableTR($mandatoryResult, $ruleCode, $type)}
                   </table>
            else
                ()

       return
            <div >
               {uiutil:javaScript()}
               {$resultText}
               {$resultTable}
               <div style="margin-top:0.5em;margin-bottom:0.5em;">
                   {uiutil:showAndHideRecordsButton($ruleCode)}
               </div>
               <div id="emptyDiv-{$ruleCode}" style="display: block;"/>
           </div>
};

(:~
: JavaScript
:)
declare function uiutil:javaScript(){

    let $js :=
           <script type="text/javascript">
               <![CDATA[
                    function toggle(emptyDiv,detailDiv, switchTextDiv, checkboxTableId, detailTableDivId, checkboxClassName) {
                        var element1 = document.getElementById(emptyDiv);
                        var element2 = document.getElementById(detailDiv);
                        var text = document.getElementById(switchTextDiv);
                        if(element1.style.display == "block") {
                                element1.style.display = "none";
                                element2.style.display = "block";
                                showAllButton(checkboxTableId, detailTableDivId, checkboxClassName,'true');
                            text.innerHTML = "Hide records";
                        }
                        else {
                            element1.style.display = "block";
                             element2.style.display = "none";
                             showAllButton(checkboxTableId, detailTableDivId, checkboxClassName,'false');
                            text.innerHTML = "Show records";
                        }
                    }

                    function showAllButton(checkboxTableId, detailTableDivId, checkboxClassName, checkOrUncheckAllCheckboxesBoolean){
                        var checkboxTable = document.getElementById(checkboxTableId);
                        if (checkboxTable) {
                            var inputElements = checkboxTable.getElementsByTagName('input');
                            for(var c = 0; c != inputElements.length; c++){
                                if(inputElements[c].className === checkboxClassName){
                                    if(checkOrUncheckAllCheckboxesBoolean=='true'){
                                        if(inputElements[c].checked==false){
                                        inputElements[c].checked=true;
                                        }
                                     }
                                     else{
                                        if(inputElements[c].checked==true){
                                        inputElements[c].checked=false;
                                        }
                                     }
                                }
                             }
                             checkboxToggle(checkboxTableId, detailTableDivId, checkboxClassName);
                         }


                     }

                   function checkboxToggle(checkboxTableId, detailTableDivId, checkboxClassName){
                        var detailTableDiv = document.getElementById(detailTableDivId);

                        var table = detailTableDiv.getElementsByTagName("table");

                        var trs=table[0].getElementsByTagName("tr") ;

                        var checkboxTable = document.getElementById(checkboxTableId);
                        var inputElements = checkboxTable.getElementsByTagName('input');


                            detailTableDiv.style.display = "none";
                            for(var k = 1; k != trs.length; k++){

                                trs[k].style.display = "none";
                            }

                            for(var c = 0; c != inputElements.length; c++){
                                 if(inputElements[c].className === checkboxClassName){
                                    if(inputElements[c].checked){
                                        detailTableDiv.style.display = "table";
                                        for(var i = 1; i != trs.length; i++){
                                            var tds=trs[i].getElementsByTagName("td");
                                            for(var j = 1; j != tds.length; j++){
                                                if(tds[j].innerHTML.length != 0){
                                                    if(tds[j].getAttribute("element") == inputElements[c].value){
                                                    trs[i].style.display = "table-row";
                                                    break;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                    }





                ]]>
           </script>
    return
        <script type="text/javascript">{normalize-space($js)}</script>
};

(: ======================================== :)
(: FUNCTIONS USED FOR FEEDBACK STATUS       :)
(: ======================================== :)

(: Feedback status: the returned string will be used as feedback status value :)
declare function uiutil:feedbackStatus($toc as element(ul)) as xs:string
{
        if (exists($toc//span[contains(., 'BLOCKER')])) then
            "BLOCKER"
        else if (exists($toc//span[contains(., 'ERROR')])) then
            "ERROR"
        else if (exists($toc//span[contains(., 'WARNING')])) then
            "WARNING"
        else
            "OK"
};

