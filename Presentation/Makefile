# Variables
MAIN = main
TEX = pdflatex
BUILDDIR = build

# Règles principales
all: $(MAIN).pdf

$(MAIN).pdf: $(MAIN).tex sections/*.tex
	@mkdir -p $(BUILDDIR)
	$(TEX) -output-directory=$(BUILDDIR) $(MAIN)
	$(TEX) -output-directory=$(BUILDDIR) $(MAIN)
	@cp $(BUILDDIR)/$(MAIN).pdf .

# Règle pour nettoyer les fichiers intermédiaires
clean:
	rm -rf $(BUILDDIR)
	rm -f $(MAIN).pdf

# Règle pour recompiler entièrement
rebuild: clean all

# Règle pour visualiser le PDF (à adapter selon le système)
view: $(MAIN).pdf
	start $(MAIN).pdf

.PHONY: all clean rebuild view