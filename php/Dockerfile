FROM php:7.4-fpm

# Install PDO MySQL extension
RUN docker-php-ext-install pdo pdo_mysql

# Optional: Install additional PHP extensions like zip, gd, etc. if needed
RUN apt-get update && apt-get install -y \
    libzip-dev \
    && docker-php-ext-install zip

EXPOSE 9000

CMD ["php-fpm"] 