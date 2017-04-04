#!/bin/sh
for txt in `ls *.txt` ; do
   mdfile=`echo $txt | sed 's/\.txt/\.md/'`
   pandoc -s -S --from=mediawiki --to=markdown_github $txt --output=$mdfile
done
