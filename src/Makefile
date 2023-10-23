fatpack:
	rm -rf local
	cpm install --target-perl 5.16
	fatpack-simple --cache ~/.perl-cpm/.fatpack-cache goenv-download -o ../bin/goenv-download
	perl-gzip-script -i ../bin/goenv-download
	chmod +x ../bin/goenv-download
