fatpack:
	rm -rf local
	cpm install --target-perl 5.8.1
	fatpack-simple --cache ~/.perl-cpm/.fatpack-cache -e Carp goenv-download -o ../bin/goenv-download
	chmod +x ../bin/goenv-download
