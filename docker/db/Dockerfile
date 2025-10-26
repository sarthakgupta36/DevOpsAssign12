# PostgreSQL Database Dockerfile
FROM postgres:13

# Set environment variables
ENV POSTGRES_DB=postgres
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres

# Copy initialization scripts
COPY init.sql /docker-entrypoint-initdb.d/

# Create a directory for custom configuration
RUN mkdir -p /etc/postgresql/conf.d

# Copy custom PostgreSQL configuration
COPY postgresql.conf /etc/postgresql/conf.d/

# Expose port
EXPOSE 5432

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD pg_isready -U postgres -d postgres || exit 1