playground/README.md: README.md
	sed -e 's/```crystal/```playground/' -e 's/require "paramnoia"/require ".\/src\/paramnoia"/' README.md > playground/README.md
