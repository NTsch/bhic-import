<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:ead="urn:isbn:1-931666-22-9"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:cei="http://www.monasterium.net/NS/cei"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:local="local"
    exclude-result-prefixes="#all">

    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

    <xsl:key name="component" match="ead:*[ead:did/@id]" use="ead:did/@id"/>
    <xsl:key name="cited-as-witness"
        match="ead:ref[@target][@xlink:role = 'inventory'][ancestor::ead:*[@otherlevel = 'Regest']]"
        use="@target"/>

    <xsl:variable name="witness-relations" as="xs:string*"
        select="('original', 'pseudo-original', 'copy', 'authenticated-copy', 'vidimus', 'insertion',
                 'extract', 'engrossment', 'draft', 'mention')"/>
    <xsl:variable name="traditio-forms" as="map(xs:string, xs:string)"
        select="map {
            'original': 'original', 'pseudo-original': 'pseudo-original', 'copy': 'copy',
            'authenticated-copy': 'authenticated copy', 'vidimus': 'vidimus', 'insertion': 'insertion',
            'extract': 'extract', 'engrossment': 'engrossment', 'draft': 'draft' }"/>

    <xsl:variable name="doc" select="/"/>
    <xsl:variable name="archive" select="normalize-space(/ead:ead/ead:eadheader/ead:filedesc/ead:publicationstmt/ead:publisher)"/>
    <xsl:variable name="fond-title" select="normalize-space(/ead:ead/ead:eadheader/ead:filedesc/ead:titlestmt/ead:titleproper)"/>
    <xsl:variable name="fond-id" select="normalize-space(/ead:ead/ead:eadheader/ead:eadid)"/>
    <xsl:variable name="has-regests" select="exists(//ead:*[@otherlevel = 'Regest'])"/>

    <xsl:template match="/ead:ead">
        <cei:cei>
            <cei:teiHeader>
                <cei:fileDesc>
                    <cei:titleStmt>
                        <cei:title><xsl:value-of select="$fond-title"/></cei:title>
                    </cei:titleStmt>
                    <cei:sourceDesc>
                        <cei:p><xsl:value-of select="$archive, 'toegang', $fond-id"/></cei:p>
                    </cei:sourceDesc>
                </cei:fileDesc>
            </cei:teiHeader>
            <cei:text>
                <cei:group>
                    <xsl:apply-templates mode="charter"
                        select="//ead:*[@otherlevel = 'Regest']
                              | //ead:*[@level = 'file'][local:marked(.)][not($has-regests) or not(key('cited-as-witness', ead:did/@id))]"/>
                </cei:group>
            </cei:text>
        </cei:cei>
    </xsl:template>

    <!-- A regest: the legal act, with its witnesses from the citations in its fields. -->
    <xsl:template match="ead:*[@otherlevel = 'Regest']" mode="charter">
        <xsl:variable name="description" select="local:lines(ead:scopecontent/ead:p)"/>
        <xsl:variable name="date-lines" select="local:date-lines($description)"/>
        <xsl:variable name="after-dates" select="$description[position() gt count($date-lines)]"/>
        <xsl:variable name="first-witness" select="(for $line in $after-dates return local:is-witness-line($line)) => index-of(true()) => head()"/>
        <xsl:variable name="summary" select="if (empty($first-witness)) then $after-dates
            else if ($first-witness gt 1) then $after-dates[position() lt $first-witness]
            else $after-dates[1]"/>
        <xsl:variable name="remaining" select="$after-dates except $summary, local:lines(ead:odd[@type = ('regest_nb', 'ONTWIKKELINGSSTADIUM')]/ead:p)"/>
        <xsl:variable name="witness-refs" select="($summary, $remaining)//ead:ref[local:is-witness-ref(.)]"/>
        <xsl:variable name="original-ref" select="$witness-refs[@xlink:arcrole = 'original'][1]"/>
        <cei:text type="charter">
            <cei:front/>
            <cei:body>
                <cei:idno id="{local:guid(.)}">
                    <xsl:value-of select="(ead:did/ead:unitid[@type = 'regest'], ead:did/@id)[normalize-space()][1]"/>
                </cei:idno>
                <cei:chDesc>
                    <cei:abstract><xsl:value-of select="$summary ! normalize-space(.)" separator=" "/></cei:abstract>
                    <cei:issued>
                        <xsl:sequence select="local:date(local:normal-date(., $date-lines), normalize-space($date-lines[last()]))"/>
                    </cei:issued>
                    <xsl:if test="$original-ref">
                        <cei:witnessOrig>
                            <cei:traditioForm><xsl:value-of select="$traditio-forms(string($original-ref/@xlink:arcrole))"/></cei:traditioForm>
                            <xsl:sequence select="local:arch-identifier($original-ref)"/>
                            <xsl:sequence select="local:physical-desc(key('component', $original-ref/@target, $doc))"/>
                            <xsl:for-each select="ead:odd[@type = 'BESCHRIJVING ZEGEL']">
                                <cei:auth><cei:sealDesc><xsl:value-of select="local:lines(ead:p) ! normalize-space(.)" separator=" "/></cei:sealDesc></cei:auth>
                            </xsl:for-each>
                        </cei:witnessOrig>
                    </xsl:if>
                    <xsl:if test="$witness-refs except $original-ref">
                        <cei:witListPar>
                            <xsl:for-each select="$witness-refs except $original-ref">
                                <cei:witness>
                                    <xsl:if test="map:contains($traditio-forms, string(@xlink:arcrole))">
                                        <cei:traditioForm><xsl:value-of select="$traditio-forms(string(@xlink:arcrole))"/></cei:traditioForm>
                                    </xsl:if>
                                    <xsl:sequence select="local:arch-identifier(.)"/>
                                </cei:witness>
                            </xsl:for-each>
                        </cei:witListPar>
                    </xsl:if>
                    <cei:diplomaticAnalysis>
                        <xsl:for-each select="$remaining[not(local:is-witness-line(.))]">
                            <cei:p><xsl:apply-templates select="node()" mode="inline"/></cei:p>
                        </xsl:for-each>
                        <xsl:for-each select="ead:odd[not(@type = ('regest_nb', 'BESCHRIJVING ZEGEL', 'ONTWIKKELINGSSTADIUM'))]">
                            <cei:p><xsl:value-of select="local:label(@type), local:lines(ead:p) ! normalize-space(.)" separator=" "/></cei:p>
                        </xsl:for-each>
                        <xsl:if test="not($original-ref)">
                            <xsl:for-each select="ead:odd[@type = 'BESCHRIJVING ZEGEL']">
                                <cei:p><xsl:value-of select="local:label(@type), local:lines(ead:p) ! normalize-space(.)" separator=" "/></cei:p>
                            </xsl:for-each>
                        </xsl:if>
                    </cei:diplomaticAnalysis>
                </cei:chDesc>
            </cei:body>
        </cei:text>
    </xsl:template>

    <!-- A file item: the physical charter, itself the original witness. -->
    <xsl:template match="ead:*[@level = 'file']" mode="charter">
        <xsl:variable name="notes" select="local:lines(ead:scopecontent/ead:p)"/>
        <cei:text type="charter">
            <cei:front/>
            <cei:body>
                <cei:idno id="{local:guid(.)}">
                    <xsl:value-of select="(ead:did/ead:unitid[not(@type)], ead:did/@id)[normalize-space()][1]"/>
                </cei:idno>
                <cei:chDesc>
                    <cei:abstract><xsl:value-of select="local:lines(ead:did/ead:unittitle) ! normalize-space(.)" separator=" "/></cei:abstract>
                    <cei:issued>
                        <xsl:sequence select="local:date(string(ead:did/ead:unitdate/@normal), normalize-space(ead:did/ead:unitdate))"/>
                    </cei:issued>
                    <cei:witnessOrig>
                        <cei:archIdentifier>
                            <xsl:sequence select="local:settlement(.)"/>
                            <cei:arch><xsl:value-of select="$archive"/></cei:arch>
                            <cei:archFond><xsl:value-of select="$fond-title"/></cei:archFond>
                            <cei:idno><xsl:value-of select="ead:did/ead:unitid[not(@type)]"/></cei:idno>
                            <xsl:sequence select="local:handle(.)"/>
                        </cei:archIdentifier>
                        <xsl:sequence select="local:physical-desc(.)"/>
                    </cei:witnessOrig>
                    <cei:diplomaticAnalysis>
                        <xsl:for-each select="$notes">
                            <cei:p><xsl:apply-templates select="node()" mode="inline"/></cei:p>
                        </xsl:for-each>
                    </cei:diplomaticAnalysis>
                </cei:chDesc>
            </cei:body>
        </cei:text>
    </xsl:template>

    <!-- Line content: text and emphasis as they are, a citation of a charter in this file as cei:ref. -->
    <xsl:template match="text()" mode="inline">
        <xsl:value-of select="."/>
    </xsl:template>

    <xsl:template match="ead:emph" mode="inline">
        <cei:hi rend="{@render}"><xsl:apply-templates select="node()" mode="inline"/></cei:hi>
    </xsl:template>

    <xsl:template match="ead:ref[@target]" mode="inline">
        <xsl:variable name="cited" select="key('component', @target, $doc)"/>
        <xsl:choose>
            <xsl:when test="local:is-charter($cited)">
                <cei:ref target="{local:guid($cited)}"><xsl:value-of select="."/></cei:ref>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="."/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="ead:*" mode="inline">
        <xsl:apply-templates select="node()" mode="inline"/>
    </xsl:template>

    <xsl:function name="local:marked" as="xs:boolean">
        <xsl:param name="component" as="element()"/>
        <xsl:sequence select="exists($component/ead:controlaccess//ead:subject[normalize-space() = 'MONASTERIUM'])"/>
    </xsl:function>

    <xsl:function name="local:is-charter" as="xs:boolean">
        <xsl:param name="component" as="element()?"/>
        <xsl:sequence select="exists($component) and (
            $component/@otherlevel = 'Regest'
            or ($component/@level = 'file' and local:marked($component) and (not($has-regests) or not(key('cited-as-witness', $component/ead:did/@id, $doc)))))"/>
    </xsl:function>

    <xsl:function name="local:guid" as="xs:string">
        <xsl:param name="component" as="element()"/>
        <xsl:sequence select="(normalize-space($component/ead:did/ead:unitid[@type = 'guid']), string($component/ead:did/@id))[. != ''][1]"/>
    </xsl:function>

    <!-- The lines of paragraphs, split at lb; each line a local:line element holding its nodes. -->
    <xsl:function name="local:lines" as="element(local:line)*">
        <xsl:param name="paragraphs" as="element()*"/>
        <xsl:for-each select="$paragraphs">
            <xsl:for-each-group select="node()" group-ending-with="ead:lb">
                <xsl:variable name="content" select="current-group()[not(self::ead:lb)]"/>
                <xsl:if test="normalize-space(string-join($content ! string(.), '')) != ''">
                    <local:line><xsl:sequence select="$content"/></local:line>
                </xsl:if>
            </xsl:for-each-group>
        </xsl:for-each>
    </xsl:function>

    <!-- The first line is the date; the second is one too when it starts with a year or with day, month and year. -->
    <xsl:function name="local:date-lines" as="element(local:line)*">
        <xsl:param name="lines" as="element(local:line)*"/>
        <xsl:sequence select="$lines[1],
            $lines[2][matches(normalize-space(.), '^(\d{4}(\D|$)|\d{1,2}\s+\p{L}+\s+\d{4}(\D|$))')][matches(normalize-space($lines[1]), '^\d{4}-\d{2}-\d{2}')]"/>
    </xsl:function>

    <xsl:function name="local:is-witness-ref" as="xs:boolean">
        <xsl:param name="ref" as="element(ead:ref)"/>
        <xsl:sequence select="$ref/@xlink:role = 'inventory' and $ref/@xlink:arcrole = $witness-relations
            and not($ref/@altrender = ('other-fond', 'obsolete-number'))"/>
    </xsl:function>

    <xsl:function name="local:is-witness-line" as="xs:boolean">
        <xsl:param name="line" as="element(local:line)"/>
        <xsl:sequence select="some $ref in $line//ead:ref satisfies local:is-witness-ref($ref)"/>
    </xsl:function>

    <!-- The normal date of a regest: the ISO date of its first line, else did/unitdate/@normal. -->
    <xsl:function name="local:normal-date" as="xs:string">
        <xsl:param name="regest" as="element()"/>
        <xsl:param name="date-lines" as="element(local:line)*"/>
        <xsl:variable name="iso" select="replace(normalize-space($date-lines[1]), '^(\d{4}-\d{2}-\d{2}).*$', '$1')"/>
        <xsl:sequence select="if (matches($iso, '^\d{4}-\d{2}-\d{2}$')) then $iso else string($regest/ead:did/ead:unitdate/@normal)"/>
    </xsl:function>

    <!-- cei:date or cei:dateRange from an EAD normal date (YYYY, YYYY-MM, YYYY-MM-DD, or two of these with /). -->
    <xsl:function name="local:date" as="element()">
        <xsl:param name="normal" as="xs:string"/>
        <xsl:param name="written" as="xs:string"/>
        <xsl:variable name="parts" select="tokenize($normal, '/')"/>
        <xsl:choose>
            <xsl:when test="count($parts) = 2 and local:date-value($parts[1]) != local:date-value($parts[2])">
                <cei:dateRange from="{local:date-value($parts[1])}" to="{local:date-value($parts[2])}"><xsl:value-of select="$written"/></cei:dateRange>
            </xsl:when>
            <xsl:otherwise>
                <cei:date value="{local:date-value($parts[1])}"><xsl:value-of select="$written"/></cei:date>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:function name="local:date-value" as="xs:string">
        <xsl:param name="normal" as="xs:string?"/>
        <xsl:variable name="fields" select="tokenize(normalize-space($normal), '-')"/>
        <xsl:sequence select="if (matches(normalize-space($normal), '^\d{4}(-\d{2}){0,2}$'))
            then concat($fields[1], ($fields[2], '99')[1], ($fields[3], '99')[1])
            else '99999999'"/>
    </xsl:function>

    <!-- archIdentifier of the item a citation names, with the page or folio of the citation line as scope. -->
    <xsl:function name="local:arch-identifier" as="element(cei:archIdentifier)">
        <xsl:param name="ref" as="element(ead:ref)"/>
        <xsl:variable name="item" select="key('component', $ref/@target, $doc)"/>
        <xsl:variable name="line" select="normalize-space($ref/ancestor::local:line)"/>
        <xsl:variable name="scope" select="replace($line, '^(.*?\W)?((pagina|folio|fol\.|f\.|p\.)\s*[\w\-]+).*$', '$2', 'i')"/>
        <cei:archIdentifier>
            <xsl:sequence select="$item ! local:settlement(.)"/>
            <cei:arch><xsl:value-of select="$archive"/></cei:arch>
            <cei:archFond><xsl:value-of select="$fond-title"/></cei:archFond>
            <cei:idno><xsl:value-of select="($item/ead:did/ead:unitid[not(@type)], $ref)[normalize-space()][1]"/></cei:idno>
            <xsl:if test="$scope != $line">
                <cei:scope><xsl:value-of select="$scope"/></cei:scope>
            </xsl:if>
            <xsl:sequence select="$item ! local:handle(.)"/>
        </cei:archIdentifier>
    </xsl:function>

    <xsl:function name="local:settlement" as="element(cei:settlement)?">
        <xsl:param name="item" as="element()"/>
        <xsl:for-each select="$item/ead:odd[@type = 'VINDPLAATS ORIGINEEL'][normalize-space()][1]">
            <cei:settlement><xsl:value-of select="normalize-space(.)"/></cei:settlement>
        </xsl:for-each>
    </xsl:function>

    <xsl:function name="local:handle" as="element(cei:ref)?">
        <xsl:param name="item" as="element()"/>
        <xsl:for-each select="$item/ead:did/ead:unitid[@type = 'handle'][normalize-space()][1]">
            <cei:ref target="{normalize-space(.)}"/>
        </xsl:for-each>
    </xsl:function>

    <xsl:function name="local:physical-desc" as="element(cei:physicalDesc)?">
        <xsl:param name="item" as="element()?"/>
        <xsl:if test="normalize-space(string-join($item/ead:did/ead:physdesc, ''))">
            <cei:physicalDesc><xsl:value-of select="$item/ead:did/ead:physdesc ! normalize-space(.)" separator="; "/></cei:physicalDesc>
        </xsl:if>
    </xsl:function>

    <xsl:function name="local:label" as="xs:string">
        <xsl:param name="type" as="xs:string?"/>
        <xsl:sequence select="concat(upper-case(substring($type, 1, 1)), lower-case(substring($type, 2)), ':')"/>
    </xsl:function>

</xsl:stylesheet>
