# README


## Steps

- To make all the files in the exp_data directory have all permissions type: `chmod -R 777 ./`
- Prevent others from seeing inside exp_data by creating an empty index html file: `touch index.html`
- Makes sure that index.html hides directory structure (for details of .htaccess, see http://www.htaccess-guide.com/directoryindex-uses/): `echo "DirectoryIndex index.html" >> .htaccess`


## Reference

https://kywch.github.io/jsPsych-in-Qualtrics/save-php/
