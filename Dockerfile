FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Instalar requisitos previos del sistema
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    sudo \
    gnupg \
    systemd \
    xmlstarlet \
    && rm -rf /var/lib/apt/lists/*

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

RUN tee /usr/local/bin/entrypoint.sh <<'EOF'
#!/bin/bash
set -e

# 1. Configurar Apache para escuchar en 8080 (Staff) y 80 (OPAC)
if ! grep -q "Listen 8080" /etc/apache2/ports.conf; then
    echo "Listen 8080" >> /etc/apache2/ports.conf
fi

# 2. Crear la instancia si no existe
if [ ! -d "/etc/koha/sites/${KOHA_INSTANCE}" ]; then
    echo "Creando instancia de Koha: ${KOHA_INSTANCE}..."
    koha-create --request-db "${KOHA_INSTANCE}"
    
    # 3. ¡ESTA ES LA CLAVE! Inyectar la configuración de la DB real
    CONF_FILE="/etc/koha/sites/${KOHA_INSTANCE}/koha-conf.xml"
    
    sed -i "s/<db_scheme>mysql<\/db_scheme>/<db_scheme>mysql<\/db_scheme>/g" $CONF_FILE
    sed -i "s/<database>koha_${KOHA_INSTANCE}<\/database>/<database>${KOHA_DBNAME}<\/database>/g" $CONF_FILE
    sed -i "s/<hostname>localhost<\/hostname>/<hostname>${KOHA_DBHOST}<\/hostname>/g" $CONF_FILE
    sed -i "s/<user>koha_${KOHA_INSTANCE}<\/user>/<user>${KOHA_DBUSER}<\/user>/g" $CONF_FILE
    sed -i "s/<pass>.*<\/pass>/<pass>${KOHA_DBPASS}<\/pass>/g" $CONF_FILE
fi

# 4. Habilitar el sitio en Apache (Koha crea el symlink pero a veces hay que forzarlo)
a2ensite "${KOHA_INSTANCE}"

# 5. Iniciar servicios
service koha-common start
exec apache2ctl -D FOREGROUND
EOF

RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]