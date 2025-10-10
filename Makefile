IMAGE_NAME ?= resume-builder
IMAGE_TAG ?= latest
OUTPUT ?= resume.pdf

.PHONY: build pdf clean docker-push

# Image that exports only resume.pdf (export stage)
IMAGE_NAME ?= resume-builder
IMAGE_TAG ?= latest

# Image for compiling arbitrary .tex sources (build stage)
LATEX_IMAGE ?= latex-env

CVS_DIR := cvs
TEX_SOURCES := $(wildcard $(CVS_DIR)/*.tex)
NAME_PREFIX ?= Artem_Mozgovoi
PDF_OUTPUTS := $(patsubst $(CVS_DIR)/%.tex,$(NAME_PREFIX)_%.pdf,$(TEX_SOURCES))

.PHONY: build latex-image pdf resume clean docker-push list

# Build full pipeline (export image containing resume.pdf from template.tex)
build:
	@docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .

# Build only the latex build-stage image for iterative compilation
latex-image:
	@docker build --target build --build-arg SKIP_TEMPLATE=1 -t $(LATEX_IMAGE):latest .

# Compile all cvs/*.tex into Artem_Mozgovoi_*.pdf
pdf: latex-image $(PDF_OUTPUTS)
	@echo "All PDFs generated: $(PDF_OUTPUTS)"

# Pattern rule to build each PDF
$(NAME_PREFIX)_%.pdf: $(CVS_DIR)/%.tex | latex-image
	@echo "[Compile] $< -> $@"; \
	SRC=$<; BASE=$$(basename $$SRC .tex); JUST=$$(basename $$SRC); NAME=$$(basename $$SRC .tex); \
	for i in 1 2; do \
	  docker run --rm -v $(PWD):/work -w /work $(LATEX_IMAGE):latest sh -c "pdflatex -interaction=nonstopmode $$SRC >/dev/null 2>&1" || { echo 'pdflatex failed'; exit 1; }; \
	done; \
	mv -f $$NAME.pdf $@; \
	rm -f $$NAME.aux $$NAME.log $$NAME.out $$NAME.toc 2>/dev/null || true

# Build just the main resume (template.tex) as resume.pdf (legacy target)
resume: build
	@cid=$$(docker create $(IMAGE_NAME):$(IMAGE_TAG)) ; \
	docker cp $$cid:/resume.pdf resume.pdf ; \
	docker rm $$cid >/dev/null ; \
	echo "Generated resume.pdf"

list:
	@echo "Detected .tex sources: $(TEX_SOURCES)"

clean:
	@rm -f template.{aux,log,out,toc,fls,fdb_latexmk,synctex.gz} resume.pdf $(PDF_OUTPUTS) \
		$(CVS_DIR)/*.aux $(CVS_DIR)/*.log $(CVS_DIR)/*.out $(CVS_DIR)/*.toc 2>/dev/null || true

# Optional: push export image (requires registry login)
docker-push: build
	@docker push $(IMAGE_NAME):$(IMAGE_TAG)
