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

# Update docker-compose.yml to mount the schema_plugins volume
echo "📝 Updating docker-compose.yml to mount schema plugins..."
# Add volume mount for schema_plugins in both geonetwork and geonetwork-replica services
sed -i '/volumes:/,/depends_on:/{
  /- geonetwork:\/catalogue-data/a\    - ./schema_plugins:/opt/geonetwork/WEB-INF/data/config/schema_plugins
}' docker-compose.yml

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

echo "✅ Setup completed successfully!"
echo ""
echo "🔧 Configuration applied:"
echo "  - GeoNetwork $VERSION Docker stack downloaded"
echo "  - iso19139.che schema plugin integrated"
echo "  - docker-compose.yml updated with schema_plugins volume mount"
echo ""
echo "🚀 Next steps:"
echo "  cd $VERSION"
echo "  make up       # Start the stack"
echo ""
echo "🌐 Services will be available at:"
echo "  - GeoNetwork: http://localhost:8080/geonetwork"
echo "  - PostgreSQL: localhost:5432"
echo "  - Elasticsearch: http://localhost:9200"
echo ""
echo "📋 Management commands:"
echo "  make down     # Stop the stack"
echo "  make clean    # Remove all containers, volumes, and images"
echo ""
echo "🗑️  To remove everything: exit the folder and run 'rm -rf $VERSION'"