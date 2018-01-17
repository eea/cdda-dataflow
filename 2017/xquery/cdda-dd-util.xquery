xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: DD Utility methods (Library module)
 :
 : Version:     $Id$
 : Created:     11 January 2018
 : Copyright:   European Environment Agency
 :)
(:~
 : Common utility methods used for extracting data from Data Dictionary
 :)
module namespace ddutil = "http://converters.eionet.europa.eu/ddutil";
import module namespace functx = "http://www.functx.com" at "cdda-functx-2017.xquery";
import module namespace cutil = "http://converters.eionet.europa.eu/cutil" at "cdda-common-util.xquery";
declare namespace dd = "http://dd.eionet.europa.eu";
declare namespace ddrdf="http://dd.eionet.europa.eu/schema.rdf#";

(:~ DD path :)
declare variable $ddutil:DD_PATH as xs:string :=  "http://dd.eionet.europa.eu"; (: + schemaId :)
(:~ DD table XML Schema URL :)
declare variable $ddutil:SCHEMA_URL as xs:string := concat($ddutil:DD_PATH, "/GetSchema?id=TBL"); (: + schemaId :)
(:~ DD table elements XML Schema URL :)
declare variable $ddutil:ELEM_SCHEMA_URL as xs:string := concat($ddutil:DD_PATH, "/GetContainerSchema?id=TBL");(: + schemaId :)
(:~ DD table elements XML Schema URL :)
declare variable $ddutil:TABLE_VIEW_URL as xs:string := concat($ddutil:DD_PATH, "/dstable.jsp?table_id=");(: + schemaId :)
(:~ DD table elements XML Schema URL :)
declare variable $ddutil:CODELIST_XML_URL as xs:string := concat($ddutil:DD_PATH, "/CodelistServlet?id="); (: + schemaId :)
(:~
 : Get DD XML Schema URL for given ID.
 : @param schemaId DD table ID
 : @return URL
 :)
declare function ddutil:getDDSchemaUrl($schemaId as xs:string)
as xs:string
{
    concat($ddutil:SCHEMA_URL, $schemaId)
};
(:~
 : Get DD table URL for given ID.
 : @param schemaId DD table ID
 : @return URL
 :)
declare function ddutil:getDDTableUrl($schemaId as xs:string)
as xs:string
{
    concat($ddutil:TABLE_VIEW_URL, $schemaId)
};
(:~
 : Get DD Elements XML Schema URL for given ID.
 : @param schemaId DD table ID
 : @return URL
 :)
declare function ddutil:getDDElemSchemaUrl($schemaId as xs:string)
as xs:string
{
    concat($ddutil:ELEM_SCHEMA_URL, $schemaId)
};
(:~
 : Get DD table code list values XML  URL
 : @param schemaId DD table ID
 : @return URL
 :)
declare function ddutil:getDDCodelistXmlUrl($schemaId as xs:string)
as xs:string
{
    concat($ddutil:CODELIST_XML_URL, $schemaId, "&amp;type=TBL&amp;format=xml")
};
(:~
 : Extract all elements from XML Schema.
 : @param schemaUrl URL of XML Schema
 : @return the list of manadatory XML element names.
 :)
declare function ddutil:getAllElements($schemaId as xs:string)
as xs:string*
{
    fn:doc(ddutil:getDDSchemaUrl($schemaId))//xs:element[@name="Row"]/xs:complexType/xs:sequence/xs:element/string(@ref)
};
(:~
 : Extract all elements with fixed values.
 : @param codeListXmlUrl URL of XML with code list elements
 : @return the list of manadatory XML element names.
 :)
declare function ddutil:getCodeListElements($schemaId as xs:string)
as xs:string*
{
    fn:doc(ddutil:getDDCodelistXmlUrl($schemaId))//dd:value-list/@element
};
(:~
 : Extract all elements with suggested values.
 : @param codeListXmlUrl URL of XML with code list elements
 : @return the list of manadatory XML element names.
 :)
declare function ddutil:getSuggestedCodeListElements($schemaId as xs:string)
as xs:string*
{
    (:fn:doc(ddutil:getDDCodelistXmlUrl($schemaId))//dd:value-list[count(@fixed)=0]/@element:)
    fn:doc(ddutil:getDDCodelistXmlUrl($schemaId))//dd:value-list[type="quantitative"]/@element
};
(:~
 : Extract all mandatory elements from XML Schema. Mandatory element minOccurs=1.
 : @param schemaUrl URL of XML Schema
 : @return the list of manadatory XML element names.
 :)
declare function ddutil:getMandatoryElements($schemaId as xs:string)
as xs:string*
{
    for $element in fn:doc(ddutil:getDDSchemaUrl($schemaId))//xs:element[@name="Row"]/xs:complexType/xs:sequence/xs:element[@minOccurs=1]
    return
        string($element/@ref)
};
(:~
 : Extract all elements with mulitvalues
 : @param schemaId DD table ID
 : @return the mapping between elements and their delimiters
 :)
declare function ddutil:getMultivalueElements($schemaId as xs:string)
as xs:string*
{
    for $element in fn:doc(ddutil:getDDSchemaUrl($schemaId))//xs:element[@name="Row"]/xs:complexType/xs:sequence/xs:element[count(@ddrdf:multiValueDelim) > 0]
    return
        cutil:createHashMapEntry(fn:substring-after($element/@ref, ":"), fn:data($element/@ddrdf:multiValueDelim))
};
(:~
 : Define elements with multivalues.
 : @param $multiValueDelimiters list of multivalue elements and their delimiters
 : @param $elemName Element name which has suggested values.
 : @return the list of suggested values.
 :)
declare function ddutil:getMultiValueDelim($multiValueDelimiters as xs:string*, $elemName as xs:string)
as xs:string
{
    let $elemName := if ( fn:contains($elemName, ":")) then fn:substring-after($elemName, ":") else $elemName
    return
        if (fn:not(fn:empty(fn:index-of(cutil:getHashMapKeys($multiValueDelimiters), $elemName)))) then
            cutil:getHashMapValue($multiValueDelimiters, $elemName)[1]
        else
            ""
}
;
(:~
 : Define all elements names to show in the header of errors table.
 : @return the list of XML element local-names (without namespace).
 :)
declare function ddutil:getElementNames($schemaId as xs:string, $nsPrefix as xs:string)
as xs:string*
{
    for $n in ddutil:getAllElements($schemaId)
    return
        replace($n, $nsPrefix, "")
};
(:~
 : Return element names with namespace prefix
 : @param $elemNames sequence of strings
 : @return Boolean value.
 :)
declare function ddutil:getElemNamesWithNs($elemNames as xs:string*, $ns as xs:string)
as xs:string*
{
    for $elemName in $elemNames
    return
        if (fn:contains($elemName, ":")) then $elemName else fn:concat($ns, $elemName)
};
