"""Transform normalized EAD files with EAD2CEI.xsl and validate each result against cei.xsd."""

import argparse
import csv
import sys
from pathlib import Path

import xmlschema
from saxonche import PySaxonProcessor

REPOSITORY = Path(__file__).resolve().parent.parent


def charter_count(path):
    return path.read_text(encoding="utf-8").count('type="charter"')


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ead", help="directory of normalized EAD files, e.g. <run>/ead")
    parser.add_argument("--out", required=True, help="directory for the CEI files and report.tsv")
    parser.add_argument("--schema", required=True, help="local path of cei.xsd")
    parser.add_argument("--xsl", default=str(REPOSITORY / "EAD2CEI.xsl"))
    parser.add_argument("--limit", type=int, help="stop after this many files")
    parser.add_argument("--dry-run", action="store_true", help="list the files that would be transformed")
    args = parser.parse_args(argv)

    sources = sorted(Path(args.ead).glob("*.xml"))[: args.limit]
    if args.dry_run:
        for source in sources:
            print(f"would write {Path(args.out) / source.name}")
        return 0
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    schema = xmlschema.XMLSchema11(args.schema)
    rows = []
    with PySaxonProcessor(license=False) as processor:
        executable = processor.new_xslt30_processor().compile_stylesheet(stylesheet_file=args.xsl)
        for source in sources:
            target = out / source.name
            executable.transform_to_file(source_file=str(source), output_file=str(target))
            if charter_count(target) == 0:
                target.unlink()
                rows.append([source.name, 0, "", "no charters: no marked item and no regest"])
                print(f"{source.name}: no charters, no file written")
                continue
            errors = list(schema.iter_errors(str(target)))
            first = f"{errors[0].path}: {errors[0].reason}" if errors else ""
            rows.append([source.name, charter_count(target), len(errors), first])
            print(f"{source.name}: {rows[-1][1]} charters, {len(errors)} schema errors {first[:160]}")
    with (out / "report.tsv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle, delimiter="\t")
        writer.writerow(["file", "charters", "schema_errors", "first_error"])
        writer.writerows(rows)
    written = [row for row in rows if row[1]]
    invalid = sum(1 for row in written if row[2])
    print(f"{len(written) - invalid} of {len(written)} files valid, {sum(row[1] for row in rows)} charters, {len(rows) - len(written)} fonds without charters")
    return 1 if invalid else 0


if __name__ == "__main__":
    sys.exit(main())
