#!/bin/sh
for txt in `find . -name "*.txt"` ; do
   if [ ! -z "$(echo $txt | sed 's/.*\.full\.txt//')" ] ; then
      mdfile=`echo $txt | sed 's/\.txt/\.md/'`
      pandoc -s --from=mediawiki --to=gfm $txt --output=$mdfile
   fi
done
