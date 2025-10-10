# Resume/CV Build Workspace

This repository contains LaTeX sources for multiple CV variants and a Docker-based reproducible build system.

## Contents
- `template.tex` – Main resume (export image builds `resume.pdf`)
- `cvs/` – Variant CVs (e.g. `engineer.tex`, `engineering_manager.tex`)
- `Makefile` – Automation for building PDFs
- `Dockerfile` – Multi-stage build; build stage provides a TeX Live toolchain

## Prerequisites
- Docker (Desktop or Colima)
- GNU Make (macOS default is fine)

## Quick Start
```bash
# Build all variant CV PDFs (cvs/*.tex) -> Artem_Mozgovoi_*.pdf
make pdf

# Build single legacy resume from template.tex -> resume.pdf
make resume

# List detected .tex sources in cvs/
make list

# Remove generated PDFs + intermediates
make clean
```

## Customizing Output Prefix
By default PDFs are named `Artem_Mozgovoi_<variant>.pdf`. Override with:
```bash
NAME_PREFIX="Artem_M" make pdf
```
This will produce e.g. `Artem_M_engineer.pdf`.

## How It Works
1. `make pdf` builds (or reuses) an image `latex-env` from the Dockerfile's `build` stage with `SKIP_TEMPLATE=1` (no compile of `template.tex`).
2. Each `cvs/<name>.tex` is compiled twice (to stabilize references) inside a transient container.
3. Resulting PDF `<name>.pdf` is renamed to `<PREFIX>_<name>.pdf` and aux/log files are removed.
4. The legacy `make resume` path builds the full multi-stage image and extracts `resume.pdf`.

## Regenerating After Edits
Just rerun:
```bash
make pdf
```
Docker layer caching will make subsequent runs faster.

## Adding a New Variant
1. Create `cvs/new_role.tex` based on an existing variant.
2. Run `make pdf`.
3. New file `Artem_Mozgovoi_new_role.pdf` appears.

## Troubleshooting
| Issue | Fix |
|-------|-----|
| Docker daemon not running | Start Docker Desktop / `colima start` |
| Missing LaTeX package error | Add package to `tlmgr install` line in `Dockerfile` and rebuild |
| Wrong prefix in filenames | Use `NAME_PREFIX=Your_Name make pdf` |
| Need faster builds | Consider switching to TinyTeX base + curated packages (open an issue / request) |

## Potential Improvements (Not Implemented Yet)
- TinyTeX-based slim image (faster pulls)
- `make bundle` target to zip all PDFs
- Lint target using `chktex`
- Watch mode (fswatch + autorebuild script)

## License
Personal use. Adapt as needed.
