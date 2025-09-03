#!/bin/bash

set -e

VERSION=${1:-4.4.2}

echo "Setting up GeoNetwork Docker stack with version $VERSION"

# Add .gitignore
echo "Updating .gitignore..."
if [ ! -f .gitignore ]; then
    touch .gitignore
fi

# Add version folder to .gitignore if not already present
if ! grep -F -q "$VERSION/" .gitignore 2>/dev/null; then
    # Ensure .gitignore ends with a newline before appending
    tail -c1 .gitignore | read -r _ || echo >> .gitignore
    echo "$VERSION/" >> .gitignore
    echo "✅ Added $VERSION/ to .gitignore"
else
    echo "ℹ️  $VERSION/ already in .gitignore"
fi

# Clean up previous version folder if exists
if [ -d "$VERSION" ]; then
    echo "Removing existing $VERSION directory..."
    rm -rf "$VERSION"
fi

# Create version directory
echo "Creating version directory $VERSION..."
mkdir -p "$VERSION"

# Move into the version directory
cd "$VERSION"

# Download GeoNetwork Docker files for the specific version
echo "Downloading GeoNetwork Docker files for version $VERSION..."
git clone --filter=blob:none --sparse --depth 1 https://github.com/geonetwork/docker-geonetwork.git temp-docker-geonetwork
cd temp-docker-geonetwork
git sparse-checkout set "$VERSION"
cd ..

# Copy files from the version directory to the current directory
if [ -d "temp-docker-geonetwork/$VERSION" ]; then
    echo "Copying Docker files for version $VERSION..."
    cp -r temp-docker-geonetwork/$VERSION/* .
else
    echo "Error: Version $VERSION not found in docker-geonetwork repository"
    echo "Available versions:"
    ls temp-docker-geonetwork/ | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | head -10
    rm -rf temp-docker-geonetwork
    exit 1
fi

# Clean up temporary repo
rm -rf temp-docker-geonetwork

# Download only the iso19139.che plugin with sparse-checkout
echo "Downloading iso19139.che plugin (optimized)..."
git clone --filter=blob:none --sparse --branch geocat_v4.2.3_report_custom_gracefull https://github.com/geoadmin/geocat.git
cd geocat
git sparse-checkout set schemas/iso19139.che/src/main/plugin/iso19139.che
cd ..

# Create schema_plugins directory and copy plugin
echo "Setting up schema plugin..."
mkdir -p schema_plugins
cp -r geocat/schemas/iso19139.che/src/main/plugin/iso19139.che ./schema_plugins/

# Clean up geocat repo
echo " Cleaning up..."
rm -rf geocat

# Update existing Dockerfile to add the iso19139.che plugin
echo " Updating existing Dockerfile..."
sed -i '/^FROM /a \
USER root\n\
# Copier le plugin iso19139.che\n\
COPY schema_plugins/iso19139.che /opt/geonetwork/WEB-INF/data/config/schema_plugins/iso19139.che\n\
# Changer les permissions\n\
RUN chown -R jetty:jetty /opt/geonetwork/WEB-INF/data/config/schema_plugins/iso19139.che\n\
USER jetty' Dockerfile

# Create Makefile for easier management
echo " Creating Makefile..."
cat > Makefile << 'EOF'
.PHONY: up down

up:
	docker compose up -d

down:
	docker compose down

clean:
	docker compose down --volumes --rmi all
EOF

echo "Setup completed successfully!"
echo ""
echo "Next steps:"
echo "  cd $VERSION"
echo "  make up       # Start the stack"
echo "  GeoNetwork is available at: http://localhost:8080/geonetwork"
echo "  PostgreSQL is available at: localhost:5432"
echo "  Elasticsearch is available at: http://localhost:9200"
echo "  make down       # Stop the stack"
echo "  make clean      # Remove all containers, volumes, and images"
echo "  Exit the folder and rm -rf $VERSION if you want to remove everything"