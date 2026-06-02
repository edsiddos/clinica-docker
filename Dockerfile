FROM php:8.3-apache

# Instala as dependências do sistema (incluindo git, unzip e libzip-dev)
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libzip-dev \
    git \
    unzip \
    && docker-php-ext-install pdo_pgsql pdo zip

# Instalação da biblioteca grafica gd e zip
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libwebp-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install gd

# Copia o binário do Composer da imagem oficial
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copia o Node.js e o npm da imagem oficial estável (LTS)
COPY --from=node:lts /usr/local/include/ /usr/local/include/
COPY --from=node:lts /usr/local/lib/ /usr/local/lib/
COPY --from=node:lts /usr/local/bin/ /usr/local/bin/

# Garante que o npm é atualizado para a última versão estável globalmente
RUN npm install -g npm@latest

# Cria variavel com o caminho da pasta public do projeto
ENV DIR_PUBLIC /var/www/html/clinica/public

# Substitui o caminho dentro dos arquivos de configuração
RUN sed -ri -e 's!/var/www/html!${DIR_PUBLIC}!g' /etc/apache2/sites-available/*.conf

# Ativa o módulo rewrite do Apache
RUN a2enmod rewrite

# Copia a configuração personalizada do PHP
COPY php.ini /usr/local/etc/php/conf.d/custom.ini

EXPOSE 80

WORKDIR /var/www/html/clinica

# Cria as pastas caso elas ainda não existam no container e define o dono como www-data
RUN mkdir -p storage bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 775 storage bootstrap/cache
