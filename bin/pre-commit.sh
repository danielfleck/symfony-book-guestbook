#!/usr/bin/env bash
PWD=`pwd`
incluir=0
composer_json_modificado=`git diff --cached --stat | grep "composer.json" | wc -l`
package_json_modificado=`git diff --cached --stat | grep "package.json" | wc -l`
licence_php_incluido=`git diff --cached --stat | grep "LICENSE_PHP_PACKAGES" | wc -l`
licence_js_incluido=`git diff --cached --stat | grep "LICENSE_JS_PACKAGES" | wc -l`

if [ $composer_json_modificado = 1 ] && [ $licence_php_incluido = 0 ];
then
	echo "Incluir LICENSE_PHP_PACKAGES";
	incluir=1
fi

if [ $package_json_modificado = 1 ] && [ $licence_js_incluido = 0 ];
then
	echo "Incluir LICENSE_JS_PACKAGES";
	incluir=1
fi

if [ $incluir = 1 ]; 
then
	cd $PWD
	make .gerar-arquivo-com-licencas;
	git add LICENSE_PHP_PACKAGES LICENSE_JS_PACKAGES;
	echo "\e[1;40;31mOs arquivos descritivos das licenças foram incluídos ao INDEX. Favor verificar efetuar um novo commit.\e[0m"
	exit 255;
fi


#if [ $package_json_modificado  >= 1 ]; 
#then 
#	if [ $(git diff --cached --stat | grep $(LICENSE_JS_PACKAGES_NAME) | wc -l) = 0 ];
#	then
#		echo "O arquivo package.json foi alterado. Favor adcionar o arquivo $(LICENSE_JS_PACKAGES_NAME) ao commit";
#		make .gerar-arquivo-com-licencas;
#		git add $(LICENSE_PHP_PACKAGES_FILE) $(LICENSE_JS_PACKAGES_FILE);
#		exit 255;
#	fi;
#fi;
#        @if [ $(git diff --cached --stat | grep "composer.json" | wc -l) >= 1 ]; \
#        then \
#                if [ $(git diff --cached --stat | grep $(LICENSE_PHP_PACKAGES_NAME) | wc -l) = 0 ]; \
#                then \  
#                        echo "O arquivo composer.json foi alterado. Favor adcionar o arquivo $(LICENSE_PHP_PACKAGES_NAME) ao commit"; \
#                        make .gerar-arquivo-com-licencas; \
#                        git add $(LICENSE_PHP_PACKAGES_FILE) $(LICENSE_JS_PACKAGES_FILE); \
#                        exit 255; \
#                fi; \
#        fi~                         
