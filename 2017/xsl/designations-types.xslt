<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:variable name="labels" select="document('labels-designations-types.xml')/labels"/>

    <xsl:template match="/">
        <html>
            <head>
                <meta charset="utf-8"/>
                <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
                <meta name="viewport" content="width=device-width, initial-scale=1"/>
                <title>Designation types report</title>
                <!-- Latest compiled and minified CSS -->
                <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css"
                      integrity="sha384-BVYiiSIFeK1dGmJRAkycuHAHRg32OmUcww7on3RYdg4Va+PmSTsz/K68vbdEjh4u"
                      crossorigin="anonymous"/>
                <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
                <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
                <!--[if lt IE 9]>
                  <script src="https://oss.maxcdn.com/html5shiv/3.7.3/html5shiv.min.js"></script>
                  <script src="https://oss.maxcdn.com/respond/1.4.2/respond.min.js"></script>
                <![endif]-->
            </head>
            <body>
                <h2>Designations</h2>
                <table class="table table-bordered table-hover">
                    <tr>
                        <th rowspan="2" style="text-align:left">
                            <xsl:value-of select="$labels/cddaCountryCode"/>
                        </th>
                        <th rowspan="2" style="text-align:left">
                            <xsl:value-of select="$labels/cddaRegionCode"/>
                        </th>
                        <th rowspan="2" style="text-align:left">
                            <xsl:value-of select="$labels/designationTypeCode"/>
                        </th>
                        <th rowspan="2" style="text-align:left">
                            <xsl:value-of select="$labels/category"/>
                        </th>
                        <th rowspan="2" style="text-align:left">
                            <xsl:value-of select="$labels/designationName"/>
                        </th>
                        <th rowspan="2" style="text-align:left">
                            <xsl:value-of select="$labels/creatingSites"/>
                        </th>
                        <th colspan="5" style="text-align:left">
                            <xsl:value-of select="$labels/legalReference"/>
                        </th>
                        <th colspan="2" style="text-align:left">
                            <xsl:value-of select="$labels/competentAuthority"/>
                        </th>
                        <th rowspan="2" style="text-align:left">
                            <xsl:value-of select="$labels/remark"/>
                        </th>
                        <th rowspan="2" style="text-align:left">
                            <xsl:value-of select="$labels/remarkSource"/>
                        </th>
                        <th colspan="2" style="text-align:left">
                            <xsl:value-of select="$labels/designationPeriod"/>
                        </th>
                    </tr>
                    <tr>
                        <th style="text-align:left">
                            <xsl:value-of select="$labels/name"/>
                        </th>
                        <th style="text-align:left">
                            <xsl:value-of select="$labels/publicationDate"/>
                        </th>
                        <th style="text-align:left">
                            <xsl:value-of select="$labels/link"/>
                        </th>
                        <th style="text-align:left">
                            <xsl:value-of select="$labels/level"/>
                        </th>
                        <th style="text-align:left">
                            <xsl:value-of select="$labels/officialJournalIdentification"/>
                        </th>
                        <th style="text-align:left">
                            <xsl:value-of select="$labels/organisationName"/>
                        </th>
                        <th style="text-align:left">
                            <xsl:value-of select="$labels/website"/>
                        </th>
                        <th style="text-align:left">
                            <xsl:value-of select="$labels/begin"/>
                        </th>
                        <th style="text-align:left">
                            <xsl:value-of select="$labels/end"/>
                        </th>
                    </tr>
                    <xsl:for-each select="designations/designation">
                        <tr>
                            <td>
                                <xsl:value-of select="cddaCountryCode"/>
                            </td>
                            <td>
                                <xsl:value-of select="cddaRegionCode"/>
                            </td>
                            <td>
                                <xsl:value-of select="designationTypeCode"/>
                            </td>
                            <td>
                                <xsl:value-of select="category"/>
                            </td>
                            <td>
                                <xsl:value-of select="designationName"/>
                            </td>
                            <td>
                                <xsl:value-of select="creatingSites"/>
                            </td>
                            <td>
                                <xsl:value-of select="legalReferenceName"/>
                            </td>
                            <td>
                                <xsl:value-of select="legalReferencePublicationDate"/>
                            </td>
                            <td>
                                <xsl:value-of select="legalReferenceLink"/>
                            </td>
                            <td>
                                <xsl:value-of select="legalReferenceLevel"/>
                            </td>
                            <td>
                                <xsl:value-of select="legalReferenceOfficialJournalIdentification"/>
                            </td>
                            <td>
                                <xsl:value-of select="competentAuthorityOrganisationName"/>
                            </td>
                            <td>
                                <xsl:value-of select="competentAuthorityWebsite"/>
                            </td>
                            <td>
                                <xsl:value-of select="remark"/>
                            </td>
                            <td>
                                <xsl:value-of select="remarkSource"/>
                            </td>
                            <td>
                                <xsl:value-of select="designationPeriodBegin"/>
                            </td>
                            <td>
                                <xsl:value-of select="designationPeriodEnd"/>
                            </td>
                        </tr>
                    </xsl:for-each>
                </table>
            </body>
        </html>
    </xsl:template>
</xsl:stylesheet>
