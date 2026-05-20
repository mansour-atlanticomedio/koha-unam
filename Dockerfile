FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Instalar requisitos previos del sistema, incluyendo 'locales' recomendado por la documentación
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    sudo \
    gnupg \
    systemd \
    xmlstarlet \
    locales \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Configurar locales para evitar advertencias y errores de traducción
RUN echo "es_ES.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen

# Configurar las llaves GPG para el repositorio de Koha
RUN mkdir -p --mode=0755 /etc/apt/keyrings && \
    curl -fsSL https://debian.koha-community.org/koha/gpg.asc -o /etc/apt/keyrings/koha.asc

# Configurar el origen de paquetes siguiendo la versión 25.05 (oldstable)
RUN tee /etc/apt/sources.list.d/koha.sources <<EOF
Types: deb
URIs: https://debian.koha-community.org/koha/
Suites: 25.05
Components: main
Signed-By: /etc/apt/keyrings/koha.asc 
EOF

# Actualizar e instalar Koha
RUN apt-get update && apt-get install -y \
    koha-common \
    && rm -rf /var/lib/apt/lists/*

# Habilitar módulos de Apache requeridos
RUN a2enmod rewrite cgi headers proxy_http

# Exponer los puertos: 80 para la interfaz pública, 8080 para la intranet del staff
EXPOSE 80 8080

# Crear un script de entrada para configurar e iniciar la instancia dinámicamente
RUN tee /usr/local/bin/entrypoint.sh <<'EOF'
#!/bin/bash
set -e

# Configurar Apache para escuchar en 8080 (Staff) y 80 (OPAC) según la documentación para IPs
if ! grep -q "Listen 8080" /etc/apache2/ports.conf; then
    echo "Listen 8080" >> /etc/apache2/ports.conf
fi

# Crear la instancia de Koha si no existe ya
if [ ! -d "/etc/koha/sites/${KOHA_INSTANCE}" ]; then
    echo "Ajustando koha-sites.conf..."
    sed -i 's/INTRAPORT="80"/INTRAPORT="8080"/' /etc/koha/koha-sites.conf
    sed -i 's/OPACPORT="80"/OPACPORT="80"/' /etc/koha/koha-sites.conf
    # Eliminamos el dominio por defecto para permitir acceso por IP
    sed -i 's/DOMAIN=".myDNSname.org"/DOMAIN=""/' /etc/koha/koha-sites.conf
    sed -i 's/DOMAIN=".localhost"/DOMAIN=""/' /etc/koha/koha-sites.conf

    echo "Configurando conexión a base de datos externa..."
    # Reemplazar koha-common.cnf según la documentación oficial
    rm -f /etc/mysql/koha-common.cnf
    cat <<EOD > /etc/mysql/koha-common.cnf
[client]
host = ${KOHA_DBHOST}
user = ${KOHA_DBUSER}
password = ${KOHA_DBPASS}
EOD

    echo "Creando instancia de Koha: ${KOHA_INSTANCE}..."
    # --request-db crea la config pero deshabilita la instancia
    koha-create --request-db "${KOHA_INSTANCE}"

    # Ajustar el XML generado para asegurar que coincida con nuestro entorno
    CONF_FILE="/etc/koha/sites/${KOHA_INSTANCE}/koha-conf.xml"
    sed -i "s/<database>koha_${KOHA_INSTANCE}<\/database>/<database>${KOHA_DBNAME}<\/database>/g" $CONF_FILE
    sed -i "s/<hostname>localhost<\/hostname>/<hostname>${KOHA_DBHOST}<\/hostname>/g" $CONF_FILE
    sed -i "s/<user>koha_${KOHA_INSTANCE}<\/user>/<user>${KOHA_DBUSER}<\/user>/g" $CONF_FILE
    sed -i "s/<pass>.*<\/pass>/<pass>${KOHA_DBPASS}<\/pass>/g" $CONF_FILE

    echo "Poblando la base de datos con las tablas de Koha..."
    koha-create --populate-db "${KOHA_INSTANCE}"

    echo "Habilitando la instancia..."
    koha-enable "${KOHA_INSTANCE}"
fi

# Forzar habilitación del sitio en Apache
a2ensite "${KOHA_INSTANCE}"

# Iniciar servicios de fondo de Koha y Apache
echo "Iniciando servicios..."
service koha-common start
exec apache2ctl -D FOREGROUND
EOF

RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]