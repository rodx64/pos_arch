FROM httpd:2.4

# Copia seus vhosts
COPY apache/httpd-vhosts.conf /usr/local/apache2/conf/extra/httpd-vhosts.conf

# Acrescenta ServerName e Include no httpd.conf ORIGINAL (dentro do container, LF)
RUN sed -i '$a ServerName localhost\nInclude conf/extra/httpd-vhosts.conf' /usr/local/apache2/conf/httpd.conf
