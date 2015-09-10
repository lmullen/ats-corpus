ats_corpus.zip : README.md manifest.csv corpus/* 
	zip -r9 $@ $^
		

download :
	Rscript download_corpus.R
