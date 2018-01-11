xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: CDDA 2014 - UI methods (Library module)
 :
 : Version:     $Id$
 : Created:     21 January 2014
 : Copyright:   European Environment Agency
 :)
(:~
 : Common utility methods related to SPARQL queries.
 :
 : @author Enriko Käsper
 :)
module namespace sparqlutil = "http://converters.eionet.europa.eu/cdda/sparql";
import module namespace cutil = "http://converters.eionet.europa.eu/cutil" at "cdda-common-util.xquery";

declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace dd = "http://dd.eionet.europa.eu";
declare namespace ddrdf="http://dd.eionet.europa.eu/schema.rdf#";

(:~ declare Content Registry SPARQL endpoint:)
declare variable $sparqlutil:CR_SPARQL_URL := "http://cr.eionet.europa.eu/sparql";
(:~ noise source :)
declare variable $sparqlutil:SITE_CODE_GRAPH := "http://dd.eionet.europa.eu/vocabulary/cdda/cddasites/rdf";
(:~ Separator used in lists expressed as string :)
declare variable $sparqlutil:LIST_ITEM_SEP := "##";

(:
 : ======================================================================
 :              SPARQL HELPER methods
 : ======================================================================
 :)

(:~ Function executes given SPARQL query and returns result elements in SPARQL result format.
 : URL parameters will be correctly encoded.
 : @param $sparql SPARQL query.
 : @return Zero or more result elements in SPARQL result format.
 :)
declare function sparqlutil:executeSparqlQuery($sparql as xs:string)
as element(sparql:result)*
{
    let $uri := sparqlutil:getSparqlEndpointUrl($sparql, "xml", fn:false())

    return
        if (fn:doc-available($uri)) then
            fn:doc($uri)/sparql:sparql/sparql:results//sparql:result
        else
            ()
};
(:~
 : Get the SPARQL endpoint URL.
 : @param $sparql SPARQL query.
 : @param $format SPARQL query.
 : @param $inference SPARQL query.
 : @return link to sparql endpoint
 :)
declare function sparqlutil:getSparqlEndpointUrl($sparql as xs:string, $format as xs:string, $inference as xs:boolean)
as xs:string
{
    let $sparql := fn:encode-for-uri(fn:normalize-space($sparql))
    let $resultFormat :=
        if ($format = "xml") then
            "application/sparql-results+xml"
        else if ($format = "html") then
            "text/html"
        else
            $format
    let $useInferencing := if ($inference) then "&amp;useInferencing=false" else ""
    let $defaultGraph := ""
    let $uriParams := concat("format=", fn:encode-for-uri($resultFormat), $defaultGraph, "&amp;query=", $sparql, $useInferencing)
    let $uri := concat($sparqlutil:CR_SPARQL_URL, "?", $uriParams)
    return $uri
};
(:~ Create SPARQL query for querying data defined in DD format.
 :)
declare function sparqlutil:getSiteCodesQuery($countryCode as xs:string)
as xs:string
{
    let $graph := $sparqlutil:SITE_CODE_GRAPH
    let $sparqlPrefixes := "PREFIX dd: <http://dd.eionet.europa.eu/schema.rdf#> "
    let $sparqlSelect :=  concat("SELECT * WHERE { GRAPH <", $graph , ">
        {
        ?s dd:siteCode ?siteCode .
        OPTIONAL {?s dd:siteName ?siteName .}
        OPTIONAL {?s dd:status ?status .}
        OPTIONAL {?s dd:yearCreated ?yearCreated .}
        OPTIONAL {?s dd:yearAllocated ?yearAllocated .}
        OPTIONAL {?s dd:yearsDeleted ?yearsDeleted .}
        OPTIONAL {?s dd:yearsDisappeared ?yearsDisappeared .}
        . ?s dd:countryAllocated <http://rdfdata.eionet.europa.eu/eea/countries/", $countryCode, ">
        }}")
    let $sparql := fn:concat($sparqlPrefixes, $sparqlSelect)

    return $sparql
};
(:~ Create SPARQL query for querying data defined in DD format.
 :)
declare function sparqlutil:getSiteCodeExistsQuery($siteCode as xs:string)
as xs:string
{
    let $graph := $sparqlutil:SITE_CODE_GRAPH
    let $sparqlPrefixes := "PREFIX dd: <http://dd.eionet.europa.eu/schema.rdf#> "
    let $sparqlSelect :=  concat("SELECT * WHERE { GRAPH <", $graph , ">
        {
        ?s dd:siteCode ", $siteCode, "
        }}")
    let $sparql := fn:concat($sparqlPrefixes, $sparqlSelect)

    return $sparql
};
