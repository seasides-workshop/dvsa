#!/bin/bash
set -e

echo "========================================="
echo "DVSA Application Setup"
echo "========================================="

echo ""
echo "Step 1: Starting Unpopular Repository..."
docker-compose up -d unpopular-repo

echo ""
echo "Step 2: Waiting for repository to be ready..."
MAX_RETRIES=60
RETRY_INTERVAL=5

for i in $(seq 1 $MAX_RETRIES); do
    if docker exec unpopular-repo curl -f -s http://localhost:8081/ > /dev/null 2>&1; then
        echo "✓ Repository is ready!"
        break
    fi
    
    if [ $i -eq $MAX_RETRIES ]; then
        echo "✗ Repository did not become ready in time"
        exit 1
    fi
    
    echo "  Waiting... ($i/$MAX_RETRIES)"
    sleep $RETRY_INTERVAL
done

echo ""
echo "Step 3: Configuring repository..."
sleep 10

REPO_PASSWORD="admin123"
if docker exec unpopular-repo test -f /nexus-data/admin.password 2>/dev/null; then
    OLD_PASSWORD=$(docker exec unpopular-repo cat /nexus-data/admin.password 2>/dev/null)
    echo "  Setting password to: admin123"
    
    for i in {1..10}; do
        HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -X PUT \
            "http://localhost:8082/service/rest/v1/security/users/admin/change-password" \
            -u "admin:${OLD_PASSWORD}" \
            -H "Content-Type: text/plain" \
            -d "${REPO_PASSWORD}" 2>/dev/null || echo "000")
        
        if [ "$HTTP_CODE" = "204" ] || [ "$HTTP_CODE" = "200" ]; then
            echo "  ✓ Password set"
            docker exec unpopular-repo rm -f /nexus-data/admin.password 2>/dev/null || true
            break
        fi
        sleep 3
    done
else
    echo "  Using default password (admin123)"
fi

echo ""
echo "Step 4: Enabling anonymous access..."
sleep 5

curl -s -X PUT "http://localhost:8082/service/rest/v1/security/anonymous" \
    -u "admin:${REPO_PASSWORD}" \
    -H "Content-Type: application/json" \
    -d '{"enabled": true, "userId": "anonymous", "realmName": "NexusAuthorizingRealm"}' \
    > /dev/null 2>&1 || echo "  Note: Anonymous access may need manual configuration"

echo "  ✓ Anonymous access enabled"

echo ""
echo "Step 5: Configuring repository to disable proxying..."
sleep 5

REPO_NAME="maven-releases"

echo "  Removing default proxy repositories..."
for proxy_repo in "maven-central" "maven-public"; do
    curl -s -X DELETE "http://localhost:8082/service/rest/v1/repositories/${proxy_repo}" \
        -u "admin:${REPO_PASSWORD}" > /dev/null 2>&1 || true
done

REPO_EXISTS=$(curl -s -u "admin:${REPO_PASSWORD}" \
    "http://localhost:8082/service/rest/v1/repositories" | \
    grep -o "\"name\":\"${REPO_NAME}\"" || echo "")

if [ -z "$REPO_EXISTS" ]; then
    echo "  Creating hosted repository (no proxying)..."
    curl -s -X POST "http://localhost:8082/service/rest/v1/repositories/maven/hosted" \
        -u "admin:${REPO_PASSWORD}" \
        -H "Content-Type: application/json" \
        -d "{
            \"name\": \"${REPO_NAME}\",
            \"online\": true,
            \"storage\": {
                \"blobStoreName\": \"default\",
                \"strictContentTypeValidation\": true,
                \"writePolicy\": \"ALLOW\"
            },
            \"maven\": {
                \"versionPolicy\": \"RELEASE\",
                \"layoutPolicy\": \"STRICT\"
            }
        }" > /dev/null 2>&1
    echo "  ✓ Hosted repository created"
else
    echo "  Checking repository type..."
    REPO_TYPE=$(curl -s -u "admin:${REPO_PASSWORD}" \
        "http://localhost:8082/service/rest/v1/repositories/${REPO_NAME}" | \
        grep -o '"type":"[^"]*"' | cut -d'"' -f4 || echo "")
    
    if [ "$REPO_TYPE" = "proxy" ]; then
        echo "  Deleting proxy repository..."
        curl -s -X DELETE "http://localhost:8082/service/rest/v1/repositories/${REPO_NAME}" \
            -u "admin:${REPO_PASSWORD}" > /dev/null 2>&1
        sleep 2
        
        echo "  Creating hosted repository (no proxying)..."
        curl -s -X POST "http://localhost:8082/service/rest/v1/repositories/maven/hosted" \
            -u "admin:${REPO_PASSWORD}" \
            -H "Content-Type: application/json" \
            -d "{
                \"name\": \"${REPO_NAME}\",
                \"online\": true,
                \"storage\": {
                    \"blobStoreName\": \"default\",
                    \"strictContentTypeValidation\": true,
                    \"writePolicy\": \"ALLOW\"
                },
                \"maven\": {
                    \"versionPolicy\": \"RELEASE\",
                    \"layoutPolicy\": \"STRICT\"
                }
            }" > /dev/null 2>&1
        echo "  ✓ Converted to hosted repository (proxying disabled)"
    else
        echo "  ✓ Repository is already hosted (no proxying)"
    fi
fi

echo ""
echo "Step 6: Configuring Gradle..."
cat > gradle.properties <<EOF
unpopularRepoUrl=http://localhost:8082
EOF

echo "✓ Gradle configuration created"

echo ""
echo "Step 7: Building and starting the application..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    UNPOPULAR_REPO_BUILD_URL="http://localhost:8082"
else
    UNPOPULAR_REPO_BUILD_URL="http://host.docker.internal:8082"
fi

docker-compose build \
    --build-arg UNPOPULAR_REPO_URL=${UNPOPULAR_REPO_BUILD_URL} \
    --build-arg UNPOPULAR_REPO_USERNAME=admin \
    --build-arg UNPOPULAR_REPO_PASSWORD=${REPO_PASSWORD} \
    --build-arg NEXUS_ALLOW_INSECURE=false \
    dvsa-app

echo "  Starting application..."
docker-compose up -d dvsa-app

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Services:"
echo "  - Unpopular Repository: http://localhost:8082 (admin/admin123, anonymous enabled)"
echo "  - Application:          http://localhost:8080"
echo ""
