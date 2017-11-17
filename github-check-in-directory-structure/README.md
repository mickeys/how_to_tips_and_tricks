# github-check-in-directory-structure

Github canonically generates a directories based upon the files and folders you've checked in.

What if you want to provide the user of your project an empty<sup>*</sup> folder hierarchy upon check-out, rather than force them to run a set-up script?

Create the nested hierarchy you desire, drop one of these .gitignore files into each directory, and check them all into github. Problem solved. 

<sup>*</sup> To the casual *NIX user it'll be an empty folder hierarchy, as dot-files are hidden. If you want to put a file with instructions into each folder, check that in and pass on the .gitignore.