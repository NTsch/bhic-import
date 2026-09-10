xquery version "3.1";
declare namespace oai = "http://www.openarchives.org/OAI/2.0/";
declare default element namespace "urn:isbn:1-931666-22-9";

let $data := collection('input/bhic/records')/oai:record/oai:metadata/ead
let $names := distinct-values($data//*[@level='file']/did/*/name())
return $names