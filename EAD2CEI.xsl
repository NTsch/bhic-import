<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:cei="http://www.monasterium.net/NS/cei"
    xmlns:ead="urn:isbn:1-931666-22-9"
    xmlns:oai="http://www.openarchives.org/OAI/2.0/"
    exclude-result-prefixes="xs math"
    version="3.0">
    
    <xsl:template match="/">
        <xsl:apply-templates/>
    </xsl:template>
    
    <!--<xsl:strip-space elements="*"/>-->
    
    <!--<xsl:template match="*|@*">
        <xsl:message>WARNING: Unprocessed node: <xsl:value-of select="name()"/></xsl:message>
    </xsl:template>-->
    
    <xsl:template match="oai:record">
        <xsl:apply-templates select="oai:metadata/ead:ead"/>
    </xsl:template>
    
    <xsl:template match='ead:ead'>
        <cei:cei>
            <xsl:apply-templates/>
        </cei:cei>
    </xsl:template>
    
    <xsl:template match='ead:eadheader'>
        <cei:teiHeader>
            <xsl:apply-templates/>
        </cei:teiHeader>
    </xsl:template>
    
    <xsl:template match='ead:eadid'/>
    
    <xsl:template match='ead:filedesc'>
        <cei:fileDesc>
            <xsl:apply-templates/>
        </cei:fileDesc>
    </xsl:template>
    
    <xsl:template match='ead:titlestmt'>
        <cei:titleStmt>
            <xsl:apply-templates/>
        </cei:titleStmt>
    </xsl:template>
    
    <xsl:template match="ead:profiledesc"/>
    
    <xsl:template match="ead:date">
        <cei:date>
            <xsl:apply-templates/>
        </cei:date>
    </xsl:template>
    
    <xsl:template match="ead:titleproper">
        <cei:title>
            <xsl:apply-templates/>
        </cei:title>
    </xsl:template>
    
    <xsl:template match="ead:subtitle">
        <cei:p>
            <xsl:apply-templates/>
        </cei:p>
    </xsl:template>
    
    <xsl:template match="ead:publicationstmt">
        <cei:publicationStmt>
            <xsl:apply-templates/>
        </cei:publicationStmt>
    </xsl:template>
    
    <xsl:template match="ead:publisher">
        <cei:publisher>
            <xsl:apply-templates/>
        </cei:publisher>
    </xsl:template>
    
    <xsl:template match="ead:address">
        <cei:pubPlace>
            <xsl:apply-templates/>
        </cei:pubPlace>
    </xsl:template>
    
    <xsl:template match="ead:archdesc">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="ead:archdesc[@level='fonds']">
        <cei:text>
            <cei:group>
                <xsl:apply-templates/>
            </cei:group>
        </cei:text>
    </xsl:template>
    
    <xsl:template match="ead:did[parent::ead:archdesc or ancestor::ead:dsc]"/>
    
    <xsl:template match="ead:controlaccess"/>
    
    <xsl:template match="ead:odd[not(@type)]"/>
    
    <xsl:template match="ead:odd[@type='REDEN GEEN UITLEEN']"/>
    
    <xsl:template match="ead:odd[@type='VINDPLAATS ORIGINEEL']">
        <cei:p>
            <xsl:text>Vindplaats origineel: </xsl:text>
            <xsl:apply-templates select=".//text()"/>
        </cei:p>
    </xsl:template>
    
    <xsl:template match="ead:unitid[@type='handle']">
        <cei:ref>
            <xsl:attribute name="target">
                <xsl:apply-templates/>
            </xsl:attribute>
        </cei:ref>
    </xsl:template>
    
    <xsl:template match="ead:unitdate">
        <cei:date value='{@normal/data()}'>
            <xsl:apply-templates/>
        </cei:date>
    </xsl:template>
    
    <xsl:template match="ead:unittitle">
        <cei:abstract>
            <xsl:apply-templates/>
        </cei:abstract>
    </xsl:template>
    
    <xsl:template match="ead:scopecontent">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="ead:p">
        <cei:p>
            <xsl:apply-templates/>
        </cei:p>
    </xsl:template>
    
    <xsl:template match="ead:*[@level='file']">
        <cei:text type='charter'>
            <cei:front/>
            <cei:body>
                <cei:idno>
                    <xsl:value-of select="ead:did/ead:unitid[not(@type)]"/>
                </cei:idno>
                <cei:chDesc>
                    <xsl:apply-templates select="ead:did/ead:unittitle"/>
                    <cei:issued>
                        <xsl:apply-templates select="ead:did/ead:unitdate"/>
                    </cei:issued>
                    <cei:witnessOrig>
                        <cei:archIdentifier>
                            <cei:arch>Brabants Historisch Informatie Centrum (BHIC)</cei:arch>
                            <cei:archFond>
                                <xsl:value-of select="ancestor::ead:ead/ead:eadheader/ead:filedesc/ead:titlestmt/ead:titleproper/text()"/>
                            </cei:archFond>
                            <cei:idno>
                                <xsl:value-of select="ead:did/ead:unitid[1]"/>
                            </cei:idno>
                            <xsl:apply-templates select="ead:did/ead:unitid[@type='handle']"/>
                        </cei:archIdentifier>
                        <cei:physicalDesc>
                            <xsl:apply-templates select="ead:controlaccess/ead:genreform"/>
                            <xsl:apply-templates select="ead:did/ead:physdesc"/>
                        </cei:physicalDesc>
                    </cei:witnessOrig>
                    <cei:diplomaticAnalysis>
                        <xsl:apply-templates select="ead:odd"></xsl:apply-templates>
                        <xsl:apply-templates select="ead:scopecontent"/>
                    </cei:diplomaticAnalysis>
                </cei:chDesc>
            </cei:body>
        </cei:text>
    </xsl:template>
    
    <!--TODO: Bilder, datevalue-->
    
</xsl:stylesheet>