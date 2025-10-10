# Minimal image for building the resume PDF (multi-arch-friendly)
FROM texlive/texlive:latest AS build

WORKDIR /work
COPY . /work

# Install only the packages we need (quietly). If already present, tlmgr exits 0.
RUN tlmgr update --self && tlmgr install \
		xcharter fontaxes mweights titlesec enumitem hyperref geometry || true

# Allow skipping template build when we only want the LaTeX environment (via build arg)
ARG SKIP_TEMPLATE=0
RUN if [ "$SKIP_TEMPLATE" = "0" ]; then \
		pdflatex -interaction=nonstopmode template.tex || (echo "First pdflatex pass failed" && cat template.log && exit 1); \
		pdflatex -interaction=nonstopmode template.tex || (echo "Second pdflatex pass failed" && cat template.log && exit 1); \
		mkdir -p output && mv template.pdf output/resume.pdf; \
	else \
		echo "Skipping template.tex build as requested"; \
	fi

# Optional export-only stage
FROM busybox:latest AS export
COPY --from=build /work/output/resume.pdf /resume.pdf
# Provide a harmless default command
CMD ["/bin/sh", "-c", "echo resume.pdf ready"]
