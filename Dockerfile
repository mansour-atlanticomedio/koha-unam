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

# Crear un script de entrada para configurar e iniciar la instancia dinámicamente
RUN tee /usr/local/bin/entrypoint.sh <<'EOF'
#!/bin/bash
set -e

# Modificar puertos de Apache si es necesario para separar Intranet y OPAC por puerto
# Forzamos a Apache a escuchar en el 8080 para la interfaz de administración
if ! grep -q "Listen 8080" /etc/apache2/ports.conf; then
    echo "Listen 8080" >> /etc/apache2/ports.conf
fi

# Ajustar koha-sites.conf antes de crear la instancia
sed -i 's/INTRAPORT="80"/INTRAPORT="8080"/' /etc/koha/koha-sites.conf
sed -i 's/OPACPORT="80"/OPACPORT="80"/' /etc/koha/koha-sites.conf
sed -i 's/DOMAIN=".localhost"/DOMAIN=""/' /etc/koha/koha-sites.conf

# Crear la instancia de Koha si no existe ya
if [ ! -d "/etc/koha/sites/library" ]; then
    echo "Creando instancia de Koha: library..."
    # Usamos --request-db porque la base de datos está en otro contenedor (MariaDB)
    koha-create --request-db library
fi

# Iniciar servicios de fondo de Koha y Apache
echo "Iniciando servicios..."
service koha-common start
# Mantener el contenedor vivo inspeccionando el log de Apache
exec apache2ctl -D FOREGROUND
EOF

RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]