# bhic-import

`EAD2CEI.xsl` turns the EAD of the BHIC Monasterium set into CEI, one `cei:cei` per fond.
It reads EAD as `harvest-oaipmh normalize` writes it: valid EAD 2002 with regest fields
in EAD elements and every citation of an inventory or regest number as `ref`.

The input is the normalized EAD of a harvest run, shared outside the repository. Put
its files into `input/bhic-ead/` (git-ignored); the Oxygen scenario `EAD2CEI` reads them
there and writes `output/cei_<file>`.

## What becomes a charter

- In a fond with regests, each regest is a charter. The inventory items its citations name
  are its witnesses: the one cited as original is `witnessOrig`, the others are
  `witListPar/witness` with the relation as `traditioForm` and page or folio as `scope`.
  Citations of other regests stay in `diplomaticAnalysis` as `cei:ref` to those charters.
- A marked file item that no regest cites as a witness is a charter of its own, with
  itself as `witnessOrig`; in a fond without regests every marked file item is one.
- Marked: `controlaccess/subject` MONASTERIUM.

The first line of a regest description is its date; the second is the date as written
when the first is an ISO date. The abstract is the description up to the first line that
cites a witness.

## Run

    uv venv .venv && uv pip install -e .
    .venv/bin/python scripts/ead2cei.py RUN/ead --out cei --schema cei.xsd

`cei.xsd` is the schema of `icaruseu/mom-ca`
(`my/XRX/src/mom/app/cei/xsd/cei.xsd`), an XSD 1.1 schema. The script writes one CEI
file per fond, `cei_<input file name>` as the Oxygen scenario names it, skips a fond without charters, validates each file and writes
`report.tsv`.
