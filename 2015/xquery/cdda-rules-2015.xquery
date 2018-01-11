xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: Common Database on Designated Areas (CDDA) (2015) - Rules methods (Library module)
 :
 : Version:     $Id$
 : Created:     21 January 2015
 : Copyright:   European Environment Agency
 :)
(:~
 : Rule definitions used by CDDA (2015) scripts.
 : Reporting obligation: http://rod.eionet.europa.eu/obligations/32
 :
 : @author Enriko Käsper and Rait Väli 
 :)
module namespace rules = "http://converters.eionet.europa.eu/cdda/rules";
import module namespace cutil = "http://converters.eionet.europa.eu/cutil" at "cdda-common-util.xquery";
import module namespace ddutil = "http://converters.eionet.europa.eu/ddutil" at "cdda-dd-util.xquery";
import module namespace uiutil = "http://converters.eionet.europa.eu/ui" at "cdda-ui-util-2015.xquery";

declare variable $rules:SITES_SCHEMA as xs:string := "9120";
declare variable $rules:SITES_NS_PREFIX as xs:string := "dd47:";
declare variable $rules:SITEBOUND_SCHEMA as xs:string := "9118";
declare variable $rules:SITEBOUND_NS_PREFIX as xs:string := "dd417:";
declare variable $rules:DESIG_SCHEMA as xs:string := "9121";
declare variable $rules:DESIG_NS_PREFIX as xs:string := "dd48:";
declare variable $rules:DESIGBOUND_SCHEMA as xs:string := "9117";
declare variable $rules:DESIGBOUND_NS_PREFIX as xs:string := "dd671:";
declare variable $rules:NATIONALOVERVIEW_SCHEMA as xs:string := "9119";
declare variable $rules:NATIONALOVERVIEW_NS_PREFIX as xs:string := "dd670:";
(:~ URL of XML file folder at Converters :)
declare variable $rules:CONVERTERS_XMLFILE_PATH as xs:string := "http://converters.eionet.europa.eu/xmlfile/";
(:~ display fields definitions XML file :)
declare variable $rules:DISPLAY_ELEMENTS_XML := concat($rules:CONVERTERS_XMLFILE_PATH, "AutomaticQA_cdda_FieldsToDisplayInResults.xml");
(:~ URL of XML file with countryies boundaires :)
declare variable $rules:MIN_MAX_URL as xs:string := "stations-min-max.xml";
(:~ URL of XML file with ISO3 country codes :)
declare variable $rules:COUNTRY_CODES_URL as xs:string := "iso3_country_codes.xml";


declare variable $rules:DATASET_NAME as xs:string := "Common Database on Designated Areas (CDDA) 2015";

declare variable $rules:RULE_REPLACE_TOKEN := "<replace>";

declare variable $rules:MANDATORY_RULE_ID := "mandatory";
declare variable $rules:MANDATORY_RULE_TITLE := "Mandatory values";
declare variable $rules:MANDATORY_RULE_DESCR := concat("This test checked the presence of mandatory elements - ", $rules:RULE_REPLACE_TOKEN, ".");
declare variable $rules:MANDATORY_RULE_MESSAGE := "Missing mandatory values have been found.";

declare variable $rules:DUPLICATES_RULE_ID := "duplicates";
declare variable $rules:DUPLICATES_RULE_TITLE := "Duplicates";
declare variable $rules:DUPLICATES_RULE_DESCR := concat("This test checked the uniqueness of primary keys. ", $rules:RULE_REPLACE_TOKEN, " should be a a unique record in the table.");
declare variable $rules:DUPLICATES_RULE_MESSAGE := "Duplicate records have been identified.";

declare variable $rules:DATATYPES_RULE_ID := "datatypes";
declare variable $rules:DATATYPES_RULE_TITLE := "Data types";
declare variable $rules:DATATYPES_RULE_DESCR := "This test checked that the format of reported elements matches the Data Dictionary specifications.";
declare variable $rules:DATATYPES_RULE_MESSAGE := "Some of the provided values are not in correct format.";

declare variable $rules:CODECONVENTION_RULE_ID := "codeconventions";
declare variable $rules:CODECONVENTION_RULE_TITLE := "Country codes";
declare variable $rules:CODECONVENTION_RULE_DESCR := concat("This test checked the correctness of country codes in ", $rules:RULE_REPLACE_TOKEN, " fields.");
declare variable $rules:CODECONVENTION_RULE_MESSAGE := "Some of the provided values do not follow the code conventions.";

declare variable $rules:CODELISTS_RULE_ID := "codelists";
declare variable $rules:CODELISTS_RULE_TITLE := "Valid codes";
declare variable $rules:CODELISTS_RULE_DESCR := concat("This test checked the correctness of values against code lists (fixed values) defined in Data Dictionary - ", $rules:RULE_REPLACE_TOKEN, ".");
declare variable $rules:CODELISTS_RULE_MESSAGE := "Some of the provided values do not exist in the relevant code lists.";

declare variable $rules:COORDINATES_RULE_ID := "coordinates";
declare variable $rules:COORDINATES_RULE_TITLE := "Coordinates";
declare variable $rules:COORDINATES_RULE_DESCR := "This test checked the correctness of coordinates against the respective country bounding boxes:";
declare variable $rules:COORDINATES_RULE_MESSAGE := "Longitude or Latitude values are outside of the bounding boxes of respective country.";

declare variable $rules:SITECODES_RULE_ID := "sitecodes";
declare variable $rules:SITECODES_RULE_TITLE := "Site codes";
declare variable $rules:SITECODES_RULE_DESCR := "This test checked that the provided site codes are allocated to the country that makes the delivery and any of the site codes that has been already discontinued or disappeared do not reappear in the delivery.";
declare variable $rules:SITECODES_RULE_MESSAGE := "Some of the provided site codes do not follow the rules.";

declare variable $rules:SITECODES_MISSING_RULE_ID := "sitecodes_missing";
declare variable $rules:SITECODES_MISSING_RULE_TITLE := "Missing sites";
declare variable $rules:SITECODES_MISSING_RULE_DESCR := "This test checked if any site record that was reported in the previous data collection delivery, and was not flagged for deletion, is missing in this delivery.";
declare variable $rules:SITECODES_MISSING_RULE_MESSAGE := "Some of the sites are missing in this delivery.";

declare variable $rules:CONSISTENCY_RULE_ID := "consistency";
declare variable $rules:CONSISTENCY_RULE_TITLE := "Marine_area_perc and Major_ecosystem_type";
declare variable $rules:CONSISTENCY_RULE_DESCR := "This test checked the consistency of Marine_area_perc and Major_ecosystem_type fields. The values are not consistent: ";
declare variable $rules:CONSISTENCY_RULE_MESSAGE := "Some of the Marine_area_perc and Major_ecosystem_type fields are invalid.";
declare variable $rules:CONSISTENCY_ADDITIONAL_MSG1 := "if Marine_area_perc = 100 and Major_ecosystem_type <> M.";
declare variable $rules:CONSISTENCY_ADDITIONAL_MSG2 := "if Marine_area_perc = 0 and Major_ecosystem_type <> T.";

declare variable $rules:DISS_CODE_ADDITIONAL_MSG := "Placeholder value 00 of the CDDA_Dissemination_code must be changed to a proper code (01-03). If not changed, all remaining 00 codes will be converted to 01 by ETC-BD when the delivery is processed.";
declare variable $rules:SITE_CODE_ADDITIONAL_MSG := "";
(:
 : Build group element for rule definitions XML.
 :)
declare function rules:buildRuleGroup($id as xs:string, $code as xs:string,
    $title as xs:string, $descr as xs:string, $descrReplacements as xs:string*,
    $message as xs:string, $messageReplacements as xs:string*, $errLevel as xs:integer, $additionalElements as node()*)
as element(group)
{
    (: do description replacements :)
    let $strDescr := cutil:replaceTokens($descr, $descrReplacements, $rules:RULE_REPLACE_TOKEN)
    let $strMsg := cutil:replaceTokens($message, $messageReplacements, $rules:RULE_REPLACE_TOKEN)
    return
    <group id="{ $id }">
        <rule code="{ $code }">
            <title>{ $title }</title>
            <descr>{ $strDescr }</descr>
            <message>{ $strMsg }</message>
            <errorLevel>{ $errLevel }</errorLevel>
            {$additionalElements}
        </rule>
    </group>
};

declare variable $rules:RULES_XML as element(root) :=
<root>
<rules title="{ $rules:DATASET_NAME } - Sites" id="{ $rules:SITES_SCHEMA }">
    {
    rules:buildRuleGroup($rules:MANDATORY_RULE_ID, "1", $rules:MANDATORY_RULE_TITLE
        , concat($rules:MANDATORY_RULE_DESCR, "")
        , (fn:replace(fn:string-join(ddutil:getMandatoryElements($rules:SITES_SCHEMA),", "), $rules:SITES_NS_PREFIX,""))
        , $rules:MANDATORY_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL,
        (<additionalDescr>All records must have the SITE_CODE field filled. If you have already spent all Site codes you have had allocated you can get a new set of codes for your sites from the Site code distribution service page <a href="http://dd.eionet.europa.eu/services/siteCodes">http://dd.eionet.europa.eu/services/siteCodes</a>. Please be aware that only appointed Reportnet users (NFP, NRC for nature) can allocate new site codes.</additionalDescr>,
        <additionalDescr>LAT and LON are mandatory if [CDDA_Coordinates_code] &lt;&gt; "02"</additionalDescr>,
        <additionalDescr>Marine_area_perc must be filled if the Major_ecosystem_type = MT</additionalDescr>))

    }{
    rules:buildRuleGroup($rules:SITECODES_RULE_ID, "2", $rules:SITECODES_RULE_TITLE, $rules:SITECODES_RULE_DESCR
        , (), $rules:SITECODES_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL,
        ())
    }{
    rules:buildRuleGroup($rules:SITECODES_MISSING_RULE_ID, "3", $rules:SITECODES_MISSING_RULE_TITLE, $rules:SITECODES_MISSING_RULE_DESCR
        , (), $rules:SITECODES_MISSING_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, ())
    }{
    rules:buildRuleGroup($rules:DUPLICATES_RULE_ID, "4", $rules:DUPLICATES_RULE_TITLE
        , "This test checked the uniqueness of SITE_CODE values."
        , ()
        , $rules:DUPLICATES_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, ())
    }{
    rules:buildRuleGroup($rules:DATATYPES_RULE_ID, "5", $rules:DATATYPES_RULE_TITLE, $rules:DATATYPES_RULE_DESCR
        , (), $rules:DATATYPES_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, ())
    }{
    rules:buildRuleGroup($rules:CODECONVENTION_RULE_ID, "6", $rules:CODECONVENTION_RULE_TITLE, $rules:CODECONVENTION_RULE_DESCR
        , ("PARENT_ISO, ISO3 and DESIG_ABBR"), $rules:CODECONVENTION_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, ())
    }{
    rules:buildRuleGroup($rules:CODELISTS_RULE_ID, "7", $rules:CODELISTS_RULE_TITLE, $rules:CODELISTS_RULE_DESCR
        , (fn:replace(fn:string-join(ddutil:getCodeListElements($rules:SITES_SCHEMA),", "), $rules:SITES_NS_PREFIX,""))
        , $rules:CODELISTS_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, (<additionalDescr>{ $rules:DISS_CODE_ADDITIONAL_MSG }</additionalDescr>))
    }{
    rules:buildRuleGroup($rules:COORDINATES_RULE_ID, "8", $rules:COORDINATES_RULE_TITLE, $rules:COORDINATES_RULE_DESCR
        , (), $rules:COORDINATES_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL
        , (
        (:<additionalDescr>{ "1. The coordinates are checked against the country polygons available at EEA Map-services." }</additionalDescr>,
            <additionalDescr>{ "2. The coordinates are checked against the country bounding boxes defined here: " }
                <a href="{ concat($rules:CONVERTERS_XMLFILE_PATH, $rules:MIN_MAX_URL) }">{ $rules:MIN_MAX_URL }</a>.</additionalDescr>:))
        )
    }
    {
    rules:buildRuleGroup($rules:CONSISTENCY_RULE_ID, "9", $rules:CONSISTENCY_RULE_TITLE, $rules:CONSISTENCY_RULE_DESCR
        , (), $rules:CONSISTENCY_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL,
        (<additionalDescr>{ $rules:CONSISTENCY_ADDITIONAL_MSG1 }</additionalDescr>,
        <additionalDescr>{ $rules:CONSISTENCY_ADDITIONAL_MSG2 }</additionalDescr>))
    }
</rules>
<rules title="{ $rules:DATASET_NAME } - Site boundaries" id="{ $rules:SITEBOUND_SCHEMA }">
    {
    rules:buildRuleGroup($rules:MANDATORY_RULE_ID, "1", $rules:MANDATORY_RULE_TITLE, $rules:MANDATORY_RULE_DESCR
        , (fn:replace(fn:string-join(ddutil:getMandatoryElements($rules:SITEBOUND_SCHEMA),", "), $rules:SITEBOUND_NS_PREFIX,""))
        , $rules:MANDATORY_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, ())
    }{
    rules:buildRuleGroup($rules:DUPLICATES_RULE_ID, "2", $rules:DUPLICATES_RULE_TITLE
        , "This test checked the uniqueness of SITE_CODE values."
        , ()
        , $rules:DUPLICATES_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, ())
    }{
    rules:buildRuleGroup($rules:DATATYPES_RULE_ID, "3", $rules:DATATYPES_RULE_TITLE, $rules:DATATYPES_RULE_DESCR
        , (), $rules:DATATYPES_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, ())
    }{
    rules:buildRuleGroup($rules:CODECONVENTION_RULE_ID, "4", $rules:CODECONVENTION_RULE_TITLE, $rules:CODECONVENTION_RULE_DESCR
        , ("PARENT_ISO and ISO3"), $rules:CODECONVENTION_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, ())
    }{
    rules:buildRuleGroup($rules:CODELISTS_RULE_ID, "5", $rules:CODELISTS_RULE_TITLE, $rules:CODELISTS_RULE_DESCR
        , (fn:replace(fn:string-join(ddutil:getCodeListElements($rules:SITEBOUND_SCHEMA),", "), $rules:SITEBOUND_NS_PREFIX,""))
        , $rules:CODELISTS_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, (<additionalDescr>{ $rules:DISS_CODE_ADDITIONAL_MSG }</additionalDescr>))
    }
</rules>
<rules title="{ $rules:DATASET_NAME } - Designations" id="{ $rules:DESIG_SCHEMA }">
    {
    rules:buildRuleGroup($rules:MANDATORY_RULE_ID, "1", $rules:MANDATORY_RULE_TITLE
        , "This test checked the presence of mandatory elements: "
        (::)
        , ()
        , $rules:MANDATORY_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL
        , (<additionalDescr>{ fn:replace(fn:string-join(rules:getDesignationMandatoryElements(),", "), $rules:DESIG_NS_PREFIX,"") }</additionalDescr>,
             <additionalDescr>{ "Category, Law, Lawreference and Agency can be empty if DESIG_ABBR ends with ""00"" or ""99""." }</additionalDescr>)
        )

    }{
    rules:buildRuleGroup($rules:DUPLICATES_RULE_ID, "2", $rules:DUPLICATES_RULE_TITLE
        , $rules:DUPLICATES_RULE_DESCR
        , ("ISO3 and DESIG_ABBR")
        , $rules:DUPLICATES_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, ())
    }{
    rules:buildRuleGroup($rules:DATATYPES_RULE_ID, "3", $rules:DATATYPES_RULE_TITLE, $rules:DATATYPES_RULE_DESCR
        , (), $rules:DATATYPES_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, ())
    }{
    rules:buildRuleGroup($rules:CODECONVENTION_RULE_ID, "4", $rules:CODECONVENTION_RULE_TITLE, $rules:CODECONVENTION_RULE_DESCR
        , ("PARENT_ISO, ISO3 and DESIG_ABBR"), $rules:CODECONVENTION_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, ())
    }{
    rules:buildRuleGroup($rules:CODELISTS_RULE_ID, "5", $rules:CODELISTS_RULE_TITLE, $rules:CODELISTS_RULE_DESCR
        , (fn:replace(fn:string-join(ddutil:getCodeListElements($rules:DESIG_SCHEMA),", "), $rules:DESIG_NS_PREFIX,""))
        , $rules:CODELISTS_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, ())
    }
</rules>
<rules title="{ $rules:DATASET_NAME } - Designation boundaries " id="{ $rules:DESIGBOUND_SCHEMA }">
    {
    rules:buildRuleGroup($rules:MANDATORY_RULE_ID, "1", $rules:MANDATORY_RULE_TITLE
        , $rules:MANDATORY_RULE_DESCR
        , (fn:replace(fn:string-join(ddutil:getMandatoryElements($rules:DESIGBOUND_SCHEMA),", "), $rules:DESIGBOUND_NS_PREFIX,""))
        , $rules:MANDATORY_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, ())
    }{
    rules:buildRuleGroup($rules:DUPLICATES_RULE_ID, "2", $rules:DUPLICATES_RULE_TITLE
        , $rules:DUPLICATES_RULE_DESCR
        , ("ISO3 and DESIG_ABBR")
        , $rules:DUPLICATES_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, ())
    }{
    rules:buildRuleGroup($rules:DATATYPES_RULE_ID, "3", $rules:DATATYPES_RULE_TITLE, $rules:DATATYPES_RULE_DESCR
        , (), $rules:DATATYPES_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, ())
    }{
    rules:buildRuleGroup($rules:CODECONVENTION_RULE_ID, "4", $rules:CODECONVENTION_RULE_TITLE, $rules:CODECONVENTION_RULE_DESCR
        , ("PARENT_ISO, ISO3 and DESIG_ABBR"), $rules:CODECONVENTION_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, ())
    }{
    rules:buildRuleGroup($rules:CODELISTS_RULE_ID, "5", $rules:CODELISTS_RULE_TITLE, $rules:CODELISTS_RULE_DESCR
        , (fn:replace(fn:string-join(ddutil:getCodeListElements($rules:DESIGBOUND_SCHEMA),", "), $rules:DESIGBOUND_NS_PREFIX,""))
        , $rules:CODELISTS_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, (<additionalDescr>{ $rules:DISS_CODE_ADDITIONAL_MSG }</additionalDescr>))
    }
</rules>
<rules title="{ $rules:DATASET_NAME } - National overview" id="{ $rules:NATIONALOVERVIEW_SCHEMA }">
    {
    rules:buildRuleGroup($rules:MANDATORY_RULE_ID, "1", $rules:MANDATORY_RULE_TITLE
        , $rules:MANDATORY_RULE_DESCR
        , (fn:replace(fn:string-join(ddutil:getMandatoryElements($rules:NATIONALOVERVIEW_SCHEMA),", "), $rules:NATIONALOVERVIEW_NS_PREFIX,""))
        , $rules:MANDATORY_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, ())
    }{
    rules:buildRuleGroup($rules:DUPLICATES_RULE_ID, "2", $rules:DUPLICATES_RULE_TITLE
        , $rules:DUPLICATES_RULE_DESCR
        , ("PARENT_ISO, ISO3, Category and Major_ecosystem")
        , $rules:DUPLICATES_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, ())
    }{
    rules:buildRuleGroup($rules:DATATYPES_RULE_ID, "3", $rules:DATATYPES_RULE_TITLE, $rules:DATATYPES_RULE_DESCR
        , (), $rules:DATATYPES_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, ())
    }{
    rules:buildRuleGroup($rules:CODECONVENTION_RULE_ID, "4", $rules:CODECONVENTION_RULE_TITLE, $rules:CODECONVENTION_RULE_DESCR
        , ("PARENT_ISO and ISO3"), $rules:CODECONVENTION_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL, ())
    }{
    rules:buildRuleGroup($rules:CODELISTS_RULE_ID, "5", $rules:CODELISTS_RULE_TITLE, $rules:CODELISTS_RULE_DESCR
        , (fn:replace(fn:string-join(ddutil:getCodeListElements($rules:NATIONALOVERVIEW_SCHEMA),", "), $rules:NATIONALOVERVIEW_NS_PREFIX,""))
        , $rules:CODELISTS_RULE_MESSAGE, (), $uiutil:ERROR_LEVEL
        ,()
         )
    }
</rules>
</root>
;


(:==================================================================
 : Functions related with rules, error codes and building the table of error messages
 :==================================================================
 :)
(:~
 : Define all fields to show in the errors table. Guarantees the correct order of elements.
 : @param $ruleCode Rule code in rules XML.
 : @param List of elment names.
 :)
declare function rules:getRuleElements($schemaId as xs:string, $nsPrefix as xs:string, $ruleCode as xs:string)
as xs:string*
{
    let $ruleElems := rules:getRuleElementsDefs($schemaId, $nsPrefix, $ruleCode)
    let $allElems := ddutil:getAllElements($schemaId)
    for $n in $allElems
    where not(empty(index-of($ruleElems, $n)))
    return $n
};
(:~
 : Define all fields to show in the errors table. Can be in random order.
 : @param $ruleCode Rule code in rules XML.
 : @param List of elment names.
 :)
declare function rules:getRuleElementsDefs($schemaId as xs:string, $nsPrefix as xs:string, $ruleCode as xs:string)
as xs:string*
{
    let $ruleElems := rules:getRuleElems($schemaId, $ruleCode)
    let $ruleElems := if (fn:empty($ruleElems)) then ddutil:getAllElements($schemaId) else $ruleElems
    for $ruleElem in $ruleElems
    return
        if (fn:starts-with($ruleElem, $nsPrefix)) then
            $ruleElem
        else
            fn:concat($nsPrefix, $ruleElem)
};
(:~
 : Get element names without namespace for given rule in correct order.
 : @param $ruleCode Rule code in rules XML.
 : @param List of elment names.
 :)
declare function rules:getRuleElementNames($schemaId as xs:string, $nsPrefix as xs:string, $ruleCode as xs:string)
as xs:string*
{
    let $elems := rules:getRuleElements($schemaId, $nsPrefix, $ruleCode)
    let $allElems := ddutil:getAllElements($schemaId)
    let $allNames :=   ddutil:getElementNames($schemaId, $nsPrefix)

    for $e in $elems
    let $idx := index-of($allElems, $e)
    return
        if (empty($idx)) then
            fn:replace($e, $nsPrefix, "")
        else
            $allNames[$idx[1]]
};
(:~
 : Get error messages for sub rules.
 : @param $ruleCode Parent rule code
 : @param $subRuleCodes List of sub rule codes.
 : @return xs:string
 :)
declare function rules:getSubRuleMessages($schemaId as xs:string, $ruleCode as xs:string, $subRuleCodes as xs:string*)
as xs:string
{
    let $rules := rules:getRules($schemaId)//group[rule/@code = $ruleCode]
    let $subRuleMessages :=
         for $subRuleCode in fn:reverse($subRuleCodes)
         let $rule := $rules//rule[@code = concat($ruleCode, ".", $subRuleCode)]
         return
             fn:concat($rule/@code, " ", $rule/message)
    return
        if (count($subRuleMessages) > 1) then string-join($subRuleMessages, "; ") else fn:string($subRuleMessages)
};
(:~
 : Get error message for given rule Code from the rules XML.
 : @param $ruleCode Rule code in rules XML.
 : @return xs:string
 :)
declare function rules:getRuleMessage($schemaId as xs:string, $ruleCode as xs:string)
as xs:string
{
    let $rule := rules:getRules($schemaId)//rule[@code = $ruleCode][1]
    return
        fn:concat($rule/@code, " ", $rule/message)
};
(:~
 : Get rule element for given rule Code from the rules XML.
 : @param $ruleCode Rule code in rules XML.
 : @return rule element.
 :)
declare function rules:getRule($schemaId as xs:string, $ruleCode as xs:string)
as element(rule)
{
    rules:getRules($schemaId)//child::rule[@code = $ruleCode][1]
(:$mandatoryElements: {fn:replace(fn:string-join(rules:getMandatoryElements(),", "),$rules:ELEM_SCHEMA_NS_PREFIX,"")}:)

};

(:~
 : Get the rule element names for given rule Code from the rules XML. The returned elements will be displayed in the result table.
 : @param $ruleCode Rule code in rules XML.
 : @return rule element.
 :)
declare function rules:getRuleElems($schemaId as xs:string, $ruleCode as xs:string)
as xs:string*
{
    let $ruleElemDefs := rules:getRuleElemDefs($schemaId)
    let $ruleTitle := rules:getRule($schemaId, $ruleCode)/title
    return
    if (fn:count($ruleElemDefs) > 0) then
        for $elemDef in $ruleElemDefs
        where $elemDef/TestId = $ruleTitle and $elemDef/DisplayField = "true"
        order by $elemDef/ElementOrder
        return
            fn:string($elemDef/ElementId)
    else
        ddutil:getAllElements($schemaId)
};
(:
    let $ruleTitle := fn:string(rules:getRules()//rule[@code = $ruleCode][1]/title)
    return
        xmlutil:getRuleElems($rules:RULE_ELEMS, $ruleTitle)
:)


declare function rules:getRules($schemaId as xs:string)
as element(rules){

    $rules:RULES_XML/child::rules[@id = $schemaId][1]

}
;
(:~
 : Get the rule element definitions for given table from the rules XML. The returned elements will be displayed in the result table.
 : @param $tableId DD table numeric ID.
 : @return rule element.
 :)
declare function rules:getRuleElemDefs($tableId as xs:string)
as element(Field)*
{
    if (fn:doc-available($rules:DISPLAY_ELEMENTS_XML)) then
        fn:doc($rules:DISPLAY_ELEMENTS_XML)//child::Field[TableId = $tableId]
    else
        ()
};

declare function rules:getDesignationMandatoryElements()
as xs:string*
{
    let $ddManadotryElements := ddutil:getMandatoryElements($rules:DESIG_SCHEMA)
    let $ddManadotryElements := distinct-values(insert-before($ddManadotryElements, count($ddManadotryElements), (concat($rules:DESIG_NS_PREFIX, "Law"), concat($rules:DESIG_NS_PREFIX, "Lawreference"),
            concat($rules:DESIG_NS_PREFIX, "Agency"))))
    return
        $ddManadotryElements
};
