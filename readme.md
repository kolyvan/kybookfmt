## KyBook Format

The KyBook file format is **TARBALL** with an e-book's content and metadata.

File path extension: *.kybook*
Possible MIME type: *application/x-kybook*

The **TARBALL** must contain:

* Manifest file (*JSON*) with a meta information about an e-book.
* Index file (*JSON*) which contains a list of files in a presentation order.

Also may contain:

* TOC file (*JSON*) with a table of content.

And certainly, **TARBALL** may include a content text files, images, audio and fonts.
The content files could be preliminarily *gzipped* and has *.gz* extension.

The text content could be in the *plain text* or in the **koobmark** format.

The typical structure of TARBALL is:

    \_manifest.json
    \_index.json
    \_toc.json
    cover.jpg
    chapter1.km.gz
    chapter2.km.gz
    ..


### Koobmark markup language

The pretty simple markup language with lots of curly brackets.

File path extension: *.km*
Possible MIME type: *application/x-koobmark*

Sample

    {h {t1 Sample title}}{%main Hello {b word.}}{f by {@kolyvan.com Kolyvan}}


### Software

The KyBook Format was designed for [**KyBook 2 Reader**](https://itunes.apple.com/ru/app/kybook-2-reader-for-epub-fb2/id1018584176) iOS application.

### License
The KyBook Format is an open source and covered by a standard 2-clause BSD license. See the LICENSE file for more info.
