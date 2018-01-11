xquery version "1.0";
(:===================================================================:)
(: Namespace declaration - if dataset declarations change, some automation is:)
(: needed here as well probably in the future:)
(:===================================================================:)
(: Dataset rule definitions and utility methods:)
import module namespace rules = "http://converters.eionet.europa.eu/cdda/rules" at "cdda-rules-2015.xquery";
(: Data Dictionary utility methods:)
import module namespace ddutil = "http://converters.eionet.europa.eu/ddutil" at "cdda-dd-util.xquery";
(: Feedback status and message :)
import module namespace uiutil = "http://converters.eionet.europa.eu/ui" at "cdda-ui-util-2015.xquery";

declare namespace xmlconv="http://converters.eionet.europa.eu/cdda/envelope";
declare namespace xsi="http://www.w3.org/2001/XMLSchema-instance";
declare namespace dd11="http://dd.eionet.europa.eu/namespace.jsp?ns_id=11";
declare namespace dd671="http://dd.eionet.europa.eu/namespace.jsp?ns_id=671";
declare namespace dd670="http://dd.eionet.europa.eu/namespace.jsp?ns_id=670";
declare namespace dd48="http://dd.eionet.europa.eu/namespace.jsp?ns_id=48";
declare namespace dd417="http://dd.eionet.europa.eu/namespace.jsp?ns_id=417";
declare namespace dd47="http://dd.eionet.europa.eu/namespace.jsp?ns_id=47";

(:===================================================================:)
(: Variable given as an external parameter by the QA service:)
(:===================================================================:)
declare variable $source_url as xs:string external;

(:==================================================================:)
(:					 STATIC 	PARAMETERS						 :)
(:==================================================================:)


declare function xmlconv:getConfigParams()   {
    let $designations_schema :=  ddutil:getDDSchemaUrl($rules:DESIG_SCHEMA)
    let $desboundaries_schema := ddutil:getDDSchemaUrl($rules:DESIGBOUND_SCHEMA)
    let $sites_schema := ddutil:getDDSchemaUrl($rules:SITES_SCHEMA)
    let $siteboundaries_schema := ddutil:getDDSchemaUrl($rules:SITEBOUND_SCHEMA)
    let $nationaloverview_schema := ddutil:getDDSchemaUrl($rules:NATIONALOVERVIEW_SCHEMA)
    let $src_url_param :=  fn:concat(fn:codepoints-to-string(38),"source_url=")

    return
        <config>
            <schemas>
                <schema type="designations">{$designations_schema}</schema>
                <schema type="desboundaries">{$desboundaries_schema}</schema>
                <schema type="sites">{$sites_schema}</schema>
                <schema type="siteboundaries">{$siteboundaries_schema}</schema>
                <schema type="nationaloverview">{$nationaloverview_schema}</schema>
                <src_url_param>{$src_url_param}</src_url_param>
            </schemas>
        </config>
}
;
(:==================================================================:)
(:==================================================================:)
(:==================================================================:)
(:						HELPERS																	 							 :)
(:==================================================================:)
(:==================================================================:)
(:==================================================================:)

(: Returns the string value shown for empty unvalid values:)
declare function xmlconv:getMissingString()  as xs:string {

    fn:string("-empty-")
}
;
(:remove secret params from URL for display:)
declare function xmlconv:getSafeUrl($url as xs:string) as xs:string{
     let $src_url_param := fn:data(xmlconv:getConfigParams()//src_url_param)
     let $safe_url :=if(contains($url,$src_url_param)) then fn:substring-after($url,$src_url_param) else $url

     return
         $safe_url

}
;

(: replaces the source file url, the url can be in source_url parameter. source_file url must be the last parameter :)
declare function xmlconv:replaceSourceUrl($url as xs:string,$url2 as xs:string) as xs:string{
     let $src_url_param := fn:data(xmlconv:getConfigParams()//src_url_param)
     let $ret_url :=if(contains($url,$src_url_param)) then fn:concat(fn:substring-before($url,$src_url_param),$src_url_param,$url2) else $url2

     return
         $ret_url

}
;
declare function xmlconv:buildTitle($title as xs:string){
    <h2>{$title}</h2>
}
;

declare function xmlconv:buildDescr($descr as xs:string){
    <p>{$descr}</p>
}
;
declare function xmlconv:buildSuccessHeader($title as xs:string, $descr as xs:string){

        let $title_result := if (string-length($title)>0 ) then xmlconv:buildTitle($title) else ""
        return
        <span>
            {$title_result}
            {xmlconv:buildDescr($descr)}
            <div result="ok" style="color:green">OK - the test was passed successfully.</div>
        </span>

}
;
declare function xmlconv:buildWarningHeader($title as xs:string, $descr as xs:string, $warn_mess as xs:string){

        let $title_result := if (string-length($title)>0 ) then xmlconv:buildTitle($title) else ""
        return
        <span>
            {$title_result}
            {xmlconv:buildDescr($descr)}
            <div result="warning" style="color:orange">WARNING - {$warn_mess}</div>
        </span>

}
;
declare function xmlconv:buildInfoHeader($title as xs:string, $descr as xs:string, $info_mess as xs:string){

        let $title_result := if (string-length($title)>0 ) then xmlconv:buildTitle($title) else ""
        return
        <span>
            {$title_result}
            {xmlconv:buildDescr($descr)}
            <div result="info" style="color:green">INFO - {$info_mess}</div>
        </span>

}
;
declare function xmlconv:buildFailedHeader($title as xs:string, $descr as xs:string, $err_mess as xs:string){

        let $title_result := if (string-length($title)>0 ) then xmlconv:buildTitle($title) else ""
        return
        <span>
            {$title_result}
            {xmlconv:buildDescr($descr)}
            {xmlconv:getFailedMessage($err_mess)}
        </span>

}
;
declare function xmlconv:getFailedMessage($err_mess as xs:string){
    let $mess := "ERROR - the test was not passed."
    let $full_mess := concat($mess, " ", $err_mess)

    return
        <div result="error" style="color:red">{$full_mess}</div>
}
;
(: checks if value is missing or not:)
declare function xmlconv:isMissingOrEmpty($node)   as xs:boolean {

     if (xmlconv:isMissing($node)) then
         fn:true()
    else
         xmlconv:isEmpty(string($node))
}
;

(: checks if value is empty or not:)
declare function xmlconv:isEmpty($value as xs:string)   as xs:boolean {

     if (fn:empty($value) or fn:string(fn:normalize-space($value))="") then
         fn:true()
    else
        fn:false()
}
;
(: checks if value is missing or not:)
declare function xmlconv:isMissing($node)   as xs:boolean {

     if (fn:count($node)=0) then
         fn:true()
    else
        fn:false()
}
;

(:==================================================================:)
(:==================================================================:)
(:==================================================================:)
(:					QA rules related functions																		  :)
(:==================================================================:)
(:==================================================================:)
(:==================================================================:)



declare function xmlconv:isAvailableFiles($url as xs:string, $file_type as xs:string)   {

 let $files :=	xmlconv:getFiles($url, $file_type)
 for $f in $files
 where
     doc-available($f)
     return
         $f
}
;

declare function xmlconv:getFiles($url as xs:string, $file_type as xs:string)   {
    let $stations_schema := fn:data(xmlconv:getConfigParams()//schema[@type=$file_type])

    for $pn in fn:doc($url)//file[@schema = $stations_schema and string-length(@link)>0]
        let $file_url := xmlconv:replaceSourceUrl($url,string($pn/@link))
        return
            $file_url
}
;
(: get Rows from xml files, even if there are several xml files with the same schema in the envelope:)
declare function xmlconv:getRows($url as xs:string, $file_type as xs:string)   {

    let $schema := fn:data(xmlconv:getConfigParams()//schema[@type=$file_type])

    for $pn in fn:doc($url)//file[@schema = $schema and string-length(@link)>0]
        let $file_url := xmlconv:replaceSourceUrl($url,string($pn/@link))
        where doc-available($file_url)
        return
                for $pn in fn:doc($file_url)//child::dd11:Row
                    return
                        $pn
}
;

(:===================================================================:)
(: QA1 - .All combinations PARENT_ISO, ISO3, DESIG_ABBR in the designation_boundaries should be available also in the designations table.. 															:)
(:===================================================================:)

declare function xmlconv:getDesignations($url as xs:string)   {

    let $title :="1. Designations - Designation boundaries"
    let $description := "All combinations PARENT_ISO, ISO3, DESIG_ABBR in the Designation boundaries should be available also in the Designations table."
    let $err_mess :="The following combinations found from Designation boundaries table are missing in the Designations table "
    let $notexists_mess :="Did not execute the script, because the Designationd or Designation boundaries table is empty"
    let $notavailable_mess :="Did not execute the script, because the  the Designationd or Designation boundaries table is not availble for QA system"

    let $designationsFileExists :=  if (count(xmlconv:getFiles($url, "designations"))>0) then fn:true() else fn:false()
    let $designationsFileAvailable := if (count(xmlconv:isAvailableFiles($url, "designations"))>0) then fn:true() else fn:false()

    let $desboundariesFileExists :=  if (count(xmlconv:getFiles($url, "desboundaries"))>0) then fn:true() else fn:false()
    let $desboundariesFileAvailable := if (count(xmlconv:isAvailableFiles($url, "desboundaries"))>0) then fn:true() else fn:false()

    let $result := xmlconv:checkDesignations($url)
    return
        if($designationsFileExists=fn:false() or $desboundariesFileExists=fn:false()) then
            xmlconv:buildInfoHeader($title,$description,$notexists_mess )
        else if($designationsFileAvailable=fn:false() or $desboundariesFileAvailable=fn:false()) then
            xmlconv:buildInfoHeader($title,$description,$notavailable_mess )
        else if(empty($result)) then
            xmlconv:buildSuccessHeader($title,$description)
        else
              <span>
                    {xmlconv:buildFailedHeader($title,$description,$err_mess)}
                    <table border="1" class="datatable">
                        <tr align="center">
                            <th>Row</th>
                            <th>PARENT_ISO</th>
                            <th>ISO3</th>
                            <th>DESIG_ABBR</th>
                        </tr>
                        {$result}
                    </table>
               </span>

}
;
declare function xmlconv:checkDesignations($url as xs:string)   {

    let $designation_rows := xmlconv:getRows($url, "designations")
    let $desboundaries_rows := xmlconv:getRows($url, "desboundaries")

    let $designation_keys :=	$designation_rows/concat(normalize-space(dd48:PARENT_ISO),"|",normalize-space(dd48:ISO3),"|",normalize-space(dd48:DESIG_ABBR))

    for $pn at $pos in $desboundaries_rows

    let $pkElem1:= data(normalize-space($pn/dd671:PARENT_ISO))
    let $pkElem2:= data(normalize-space($pn/dd671:ISO3))
    let $pkElem3:= data(normalize-space($pn/dd671:DESIG_ABBR))

    let $isInvalid := count(index-of($designation_keys,concat($pkElem1,"|",$pkElem2,"|",$pkElem3)))=0  and not(xmlconv:isMissingOrEmpty($pkElem1))  and not(xmlconv:isMissingOrEmpty($pkElem2))  and not(xmlconv:isMissingOrEmpty($pkElem3))

    where $isInvalid
    return
            <tr>
                    <td>{$pos}</td>
                    <td>{$pkElem1}</td>
                    <td>{$pkElem2}</td>
                    <td>{$pkElem3}</td>
            </tr>
}
;

(:===================================================================:)
(: QA2 - check whether all combiantions PARENT_ISO, DESIG_ABBR in the sites table are available also in the designations table;  :)
(:		compare only records which have "To_be_deleted" = False (both tables) -  :)
(: for example, if site record is not to be deleted and the combination exists in the designation table but is marked to be deleted it is an error.. 															:)
(:===================================================================:)

declare function xmlconv:getSiteDesignations($url as xs:string)   {

    let $title :="2. Sites - Designations"
    let $description := "All combiantions of PARENT_ISO and DESIG_ABBR in the Sites table should be available also in the Designations table. Only rows which have 'To_be_deleted' = False (both tables) will be compared."
    let $err_mess :="The following combinations found from Sites table are missing in the Designations table "
    let $notexists_mess :="Did not execute the script, because the Sites or Designations table is empty"
    let $notavailable_mess :="Did not execute the script, because the  the Sites or Designations table is not availble for QA system"

    let $designationsFileExists :=  if (count(xmlconv:getFiles($url, "designations"))>0) then fn:true() else fn:false()
    let $designationsFileAvailable := if (count(xmlconv:isAvailableFiles($url, "designations"))>0) then fn:true() else fn:false()

    let $sitesFileExists :=  if (count(xmlconv:getFiles($url, "sites"))>0) then fn:true() else fn:false()
    let $sitesFileAvailable := if (count(xmlconv:isAvailableFiles($url, "sites"))>0) then fn:true() else fn:false()

    let $result := xmlconv:checkSiteDesignations($url)
    return
        if($designationsFileExists=fn:false() or $sitesFileExists=fn:false()) then
            xmlconv:buildInfoHeader($title,$description,$notexists_mess )
        else if($designationsFileAvailable=fn:false() or $sitesFileAvailable=fn:false()) then
            xmlconv:buildInfoHeader($title,$description,$notavailable_mess )
        else if(empty($result)) then
            xmlconv:buildSuccessHeader($title,$description)
        else
              <span>
                    {xmlconv:buildFailedHeader($title,$description,$err_mess)}
                    <table border="1" class="datatable">
                        <tr align="center">
                            <th>Row</th>
                            <th>PARENT_ISO</th>
                            <th>DESIG_ABBR</th>
                            <th>To be deleted</th>
                        </tr>
                        {$result}
                    </table>
               </span>

}
;
declare function xmlconv:checkSiteDesignations($url as xs:string)   {

    let $designation_rows := xmlconv:getRows($url, "designations")
    let $sites_rows := xmlconv:getRows($url, "sites")

    let $designation_keys :=	$designation_rows/concat(normalize-space(dd48:PARENT_ISO),"|",normalize-space(dd48:DESIG_ABBR),"|",normalize-space(dd48:To_be_deleted))

    for $pn at $pos in $sites_rows

    let $pkElem1:= data(normalize-space($pn/dd47:PARENT_ISO))
    let $pkElem2:= data(normalize-space($pn/dd47:DESIG_ABBR))
    let $toBeDeleted := data(normalize-space($pn/dd47:To_be_deleted))

    let $isInvalid := count(index-of($designation_keys,concat($pkElem1,"|",$pkElem2,"|",$toBeDeleted)))=0  and not(xmlconv:isMissingOrEmpty($pkElem1))  and not(xmlconv:isMissingOrEmpty($pkElem2))  and not(xmlconv:isMissingOrEmpty($toBeDeleted)) and
            fn:lower-case($toBeDeleted) = "false"

    where $isInvalid
    return
            <tr>
                    <td>{$pos}</td>
                    <td>{$pkElem1}</td>
                    <td>{$pkElem2}</td>
                    <td>{$toBeDeleted}</td>
            </tr>
}
;

(:===================================================================:)
(: QA3 - (3) sites - site_boundaries														:)
(: 	- every site (not marked as to be deleted) has to have a entry in the site_boundaries table - combination SITE_CODE, SITE_CODE_NAT, PARENT_ISO, ISO3  :)
(: 	- each of the combinations in the sites_boundary table must be available in the sites table  :)
(: 	- if site.CDDA_coordinates_code = "02" then site_boundaries.CDDA_Availability_code must be "01"	:)
(:===================================================================:)

declare function xmlconv:getSites($url as xs:string)   {

    let $title :="3. Sites - Site boundaries"
    let $description1 := "3.1 All combiantions of SITE_CODE, SITE_CODE_NAT, PARENT_ISO, ISO3 in the Sites table should be available also in the Site boundaries table. Only rows which have 'To_be_deleted' = False will be compared."
    let $description2 := "3.2 All combiantions of SITE_CODE, SITE_CODE_NAT, PARENT_ISO, ISO3 in the Site boundaries table should be available also in the Sites table."
    let $description3 := "3.3  Each site which have CDDA_coordinates_code = '02' should have CDDA_Availability_code='01' in Site boundaries table."
    let $err_mess1 :="The following combinations found from Sites table are missing in the Site boundaries table "
    let $err_mess2 :="The following combinations found from Site boundaries table are missing in the Sites table "
    let $err_mess3 :="The following sites do not have correct values in checked fields."
    let $notexists_mess :="Did not execute the script, because the Sites or Site boundaries table is empty"
    let $notavailable_mess :="Did not execute the script, because the  the Sites or Site boundaries table is not availble for QA system"

    let $sitesFileExists :=  if (count(xmlconv:getFiles($url, "sites"))>0) then fn:true() else fn:false()
    let $sitesFileAvailable := if (count(xmlconv:isAvailableFiles($url, "sites"))>0) then fn:true() else fn:false()

    let $siteboundariesFileExists :=  if (count(xmlconv:getFiles($url, "siteboundaries"))>0) then fn:true() else fn:false()
    let $siteboundariesFileAvailable := if (count(xmlconv:isAvailableFiles($url, "siteboundaries"))>0) then fn:true() else fn:false()

    let $result1 := xmlconv:checkSites($url)
    let $result2 := xmlconv:checkSiteBoundaries($url)
    let $result3 := xmlconv:checkSiteAvailability($url)

    return
        if($siteboundariesFileExists=fn:false() or $sitesFileExists=fn:false()) then
            xmlconv:buildInfoHeader($title,$description1,$notexists_mess )
        else if($siteboundariesFileAvailable=fn:false() or $sitesFileAvailable=fn:false()) then
            xmlconv:buildInfoHeader($title,$description1,$notavailable_mess )
        else
              <span>
                    {xmlconv:buildTitle($title)}
                  {
                    if(empty($result1)) then
                        xmlconv:buildSuccessHeader("",$description1)
                    else
                        <div>
                        {xmlconv:buildFailedHeader("",$description1,$err_mess1)}
                        <table border="1" class="datatable">
                            <tr align="center">
                                <th>Row</th>
                                <th>SITE_CODE</th>
                                <th>SITE_CODE_NAT</th>
                                <th>PARENT_ISO</th>
                                <th>ISO3</th>
                            </tr>
                            {$result1}
                        </table>
                    </div>
                    }
                  {
                    if(empty($result2)) then
                        xmlconv:buildSuccessHeader("",$description2)
                    else
                        <div>
                            {xmlconv:buildFailedHeader("",$description2,$err_mess2)}
                            <table border="1" class="datatable">
                                <tr align="center">
                                    <th>Row</th>
                                    <th>SITE_CODE</th>
                                    <th>SITE_CODE_NAT</th>
                                    <th>PARENT_ISO</th>
                                    <th>ISO3</th>
                                </tr>
                                {$result2}
                            </table>
                        </div>
                    }
                  {
                    if(empty($result3)) then
                        xmlconv:buildSuccessHeader("",$description3)
                    else
                        <div>
                            {xmlconv:buildFailedHeader("",$description3,$err_mess3)}
                            <table border="1" class="datatable">
                                <tr align="center">
                                    <th>Row</th>
                                    <th>SITE_CODE</th>
                                    <th>SITE_CODE_NAT</th>
                                    <th>PARENT_ISO</th>
                                    <th>ISO3</th>
                                    <th>CDDA_coordinates_code</th>
                                    <th>CDDA_Availability_code</th>
                                </tr>
                                {$result3}
                            </table>
                        </div>
                    }
               </span>

}
;
declare function xmlconv:checkSites($url as xs:string)   {

    let $siteboundaries_rows := xmlconv:getRows($url, "siteboundaries")
    let $sites_rows := xmlconv:getRows($url, "sites")

    let $siteboundaries_keys :=	$siteboundaries_rows/concat(normalize-space(dd417:SITE_CODE),"|",normalize-space(dd417:SITE_CODE_NAT),"|",normalize-space(dd417:PARENT_ISO),"|",normalize-space(dd417:ISO3))

    for $pn at $pos in $sites_rows

    let $pkElem1:= data(normalize-space($pn/dd47:SITE_CODE))
    let $pkElem2:= data(normalize-space($pn/dd47:SITE_CODE_NAT))
    let $pkElem3:= data(normalize-space($pn/dd47:PARENT_ISO))
    let $pkElem4:= data(normalize-space($pn/dd47:ISO3))
    let $toBeDeleted := data(normalize-space($pn/dd47:To_be_deleted))

    let $isInvalid := count(index-of($siteboundaries_keys,concat($pkElem1,"|",$pkElem2,"|",$pkElem3,"|",$pkElem4)))=0  and (not(xmlconv:isMissingOrEmpty($pkElem1))  or not(xmlconv:isMissingOrEmpty($pkElem2))) and
            not(xmlconv:isMissingOrEmpty($pkElem4)) and not(xmlconv:isMissingOrEmpty($pkElem3))  and not(xmlconv:isMissingOrEmpty($toBeDeleted)) and	fn:lower-case($toBeDeleted) = "false"

    where $isInvalid
    return
            <tr>
                    <td>{$pos}</td>
                    <td>{$pkElem1}</td>
                    <td>{$pkElem2}</td>
                    <td>{$pkElem3}</td>
                    <td>{$pkElem4}</td>
            </tr>
}
;
declare function xmlconv:checkSiteBoundaries($url as xs:string)   {

    let $siteboundaries_rows := xmlconv:getRows($url, "siteboundaries")
    let $site_rows := xmlconv:getRows($url, "sites")

    let $site_keys :=	$site_rows/concat(normalize-space(dd47:SITE_CODE),"|",normalize-space(dd47:SITE_CODE_NAT),"|",normalize-space(dd47:PARENT_ISO),"|",normalize-space(dd47:ISO3))

    for $pn at $pos in $siteboundaries_rows

    let $pkElem1:= data(normalize-space($pn/dd417:SITE_CODE))
    let $pkElem2:= data(normalize-space($pn/dd417:SITE_CODE_NAT))
    let $pkElem3:= data(normalize-space($pn/dd417:PARENT_ISO))
    let $pkElem4:= data(normalize-space($pn/dd417:ISO3))

    let $isInvalid := count(index-of($site_keys,concat($pkElem1,"|",$pkElem2,"|",$pkElem3,"|",$pkElem4)))=0  and (not(xmlconv:isMissingOrEmpty($pkElem1))  or not(xmlconv:isMissingOrEmpty($pkElem2))) and
            not(xmlconv:isMissingOrEmpty($pkElem4)) and not(xmlconv:isMissingOrEmpty($pkElem3))

    where $isInvalid
    return
            <tr>
                    <td>{$pos}</td>
                    <td>{$pkElem1}</td>
                    <td>{$pkElem2}</td>
                    <td>{$pkElem3}</td>
                    <td>{$pkElem4}</td>
            </tr>
}
;

declare function xmlconv:checkSiteAvailability($url as xs:string)   {

    let $siteboundaries_rows := xmlconv:getRows($url, "siteboundaries")
    let $sites_rows := xmlconv:getRows($url, "sites")

    let $siteboundaries_keys :=	$siteboundaries_rows/concat(normalize-space(dd417:SITE_CODE),"|",normalize-space(dd417:SITE_CODE_NAT),"|",normalize-space(dd417:PARENT_ISO),"|",normalize-space(dd417:ISO3))
    let $CDDA_Availability_codes :=	$siteboundaries_rows/normalize-space(dd417:CDDA_Availability_code)

    for $pn at $pos in $sites_rows

    let $pkElem1:= data(normalize-space($pn/dd47:SITE_CODE))
    let $pkElem2:= data(normalize-space($pn/dd47:SITE_CODE_NAT))
    let $pkElem3:= data(normalize-space($pn/dd47:PARENT_ISO))
    let $pkElem4:= data(normalize-space($pn/dd47:ISO3))
    let $CDDA_coordinates_code := data(normalize-space($pn/dd47:CDDA_Coordinates_code))

    let $CDDA_Availability_code := string($CDDA_Availability_codes[index-of($siteboundaries_keys,concat($pkElem1,"|",$pkElem2,"|",$pkElem3,"|",$pkElem4))[1]])

    let $isInvalid :=
            if($CDDA_coordinates_code="02") then
                not($CDDA_Availability_code="01")
            else
                fn:false()


    where $isInvalid
    return
            <tr>
                    <td>{$pos}</td>
                    <td>{$pkElem1}</td>
                    <td>{$pkElem2}</td>
                    <td>{$pkElem3}</td>
                    <td>{$pkElem4}</td>
                    <td>{$CDDA_coordinates_code}</td>
                    <td style="color:red">{if ($CDDA_Availability_code="") then xmlconv:getMissingString() else  $CDDA_Availability_code}</td>
            </tr>
}
;



(:===================================================================:)
(: Main function calls the different get function and returns the result:)
(:===================================================================:)

declare function xmlconv:proceed($url as xs:string) {
    let $resultDesignations := xmlconv:getDesignations($url)
    let $resultSiteDesignations := xmlconv:getSiteDesignations($url)
    let $resultSites := xmlconv:getSites($url)
    let $thisResult := <div result="envelope">{$resultDesignations, $resultSiteDesignations, $resultSites}</div>

    return
    <div class="feedbacktext">
        {uiutil:feedbackStatusAndMessage($thisResult)}
        <h2>The following cross table checks were made against CDDA envelope</h2>
         {$thisResult}
    </div>
}
;

(:==================================================================:)
(: This is the actual call of the function:)
(:==================================================================:)
(:
xmlconv:proceed("http://cdrtest.eionet.europa.eu/ee/eea/colqrajqw/envsjv9ya/xml")
xmlconv:proceed("../test/cdda_envelope.xml")
xmlconv:proceed($source_url)

:)
xmlconv:proceed($source_url)
