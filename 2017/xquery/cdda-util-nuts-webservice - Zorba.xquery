xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: CDDA 2017 (Library module)
 :
 : Version:     $Id$
 : Created:     11 January 2018
 : Copyright:   European Environment Agency
 :)
(:~
 : Common utility methods used by CDDA 2012 scripts.
 : Reporting obligation: http://rod.eionet.europa.eu/obligations/32
 :
 : This module sends requests to EEA's Mapservice and helps to validate country coordinates
 :
 :)
(:===================================================================:)
(: Namespace declaration                                             :)
(:===================================================================:)
module namespace nutsws = "http://converters.eionet.europa.eu/cdda/nutsws";

(: the following import is needed only when executing the script on Zorba engine. :)

declare namespace xmlconv-json = "java:eionet.gdem.qa.functions.Json";
import module namespace parse-xml = "http://www.zorba-xquery.com/modules/xml";

(:~
 : LOCAL - uses local Java method to call NUTS webservice and converting the JSON result to XML
 : REMOTE - uses Remote REST method to call NUTS webservice and converting the JSON result to XML
 :)
declare variable $nutsws:useLocalOrRemoteMethod as xs:string := "REMOTE";
(:~
 : Remote converter URL for JSON -> XML conversion
 :)
declare variable $nutsws:remoteJson2XmlConverterUrl as xs:string := "http://converterstest.eionet.europa.eu/api/convertJson2Xml?json=";
(: Webservice URL :)
declare variable $nutsws:NUTS_WEBSERVICE_URL as xs:string := "http://discomap.eea.europa.eu/ArcGIS/rest/services/ExtractData/Validate/GPServer/GeoValidate/execute";
(: Send reqeusts to webservice in several groups, otherwise the URL might be too long. Parameter indicates the group size. :)
declare variable $nutsws:FIELD_GROUP_SIZE := 15;

(:~
 : Function calls webservice URL which returns results in JSON format. The result is transformed to XML useing Zorba or Saxon impl.
 : @param serviceUrl RESTful webservice URL that return JSON format
 : @param rootElem element name in result XML that will be returned as method response
 :)
declare function nutsws:callJsonWebservice($serviceUrl as xs:string, $rootElem as xs:string)
as node()*
{
    (: FIXME change the following row depending on the environment :)
    (:
    nutsws:callSaxonImpl($rootElem)
    :)
    nutsws:callZorbaImpl($serviceUrl, $rootElem)
};

declare function nutsws:callSaxonImpl($serviceUrl as xs:string, $rootElem as xs:string)
as node()*
{
(:
    FIXME for using SAXON engine remove comments
    :)
    let $nutsWebserviceResultXml :=
        if ( $nutsws:useLocalOrRemoteMethod = "LOCAL" ) then
               ()(:
            xmlconv-json:jsonRequest2xml($serviceUrl)
:)
        else
            fn:doc(concat($nutsws:remoteJson2XmlConverterUrl, fn:encode-for-uri($serviceUrl)))
    let $resultsValueElement := $nutsWebserviceResultXml//*[name() = $rootElem][1]
    let $resultFields :=
        if (not(empty($resultsValueElement))) then
            ()(:
            saxon:parse($resultsValueElement)
            :)
        else
            ()
    return
        $resultFields
};

declare function nutsws:callZorbaImpl($serviceUrl as xs:string, $rootElem as xs:string)
as node()*
{
(:
    ()
    FIXME for using ZORBA engine remove comments
:)
    let $nutsWebserviceResultXml :=
            fn:doc(concat($nutsws:remoteJson2XmlConverterUrl, fn:encode-for-uri($serviceUrl)))
    let $resultsValueElement := $nutsWebserviceResultXml//*[name() = $rootElem][1]
    let $resultFields := parse-xml:parse-xml-fragment($resultsValueElement, "")
    return
        $resultFields
};
