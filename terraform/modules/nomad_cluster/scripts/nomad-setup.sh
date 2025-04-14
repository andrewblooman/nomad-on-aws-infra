#!/bin/bash
# This script is designed to be passed to Bottlerocket's admin container
# It installs and configures Nomad on Bottlerocket

# Set up environment
set -e
NOMAD_VERSION="1.8.3"
DOWNLOAD_URL="https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip"
NOMAD_DIR="/opt/nomad"

# Create directories
mkdir -p ${NOMAD_DIR}/bin
mkdir -p ${NOMAD_DIR}/data
mkdir -p ${NOMAD_DIR}/config

# Download and install Nomad
curl -L -o /tmp/nomad.zip ${DOWNLOAD_URL}
unzip /tmp/nomad.zip -d ${NOMAD_DIR}/bin
chmod +x ${NOMAD_DIR}/bin/nomad
rm /tmp/nomad.zip

# Create systemd service file
cat > /etc/systemd/system/nomad.service << EOF
[Unit]
Description=Nomad
Documentation=https://www.nomadproject.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=${NOMAD_DIR}/bin/nomad agent -config=${NOMAD_DIR}/config
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=2
StartLimitBurst=3
StartLimitIntervalSec=10
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Create Nomad server config for OIDC
cat > ${NOMAD_DIR}/config/oidc.hcl << EOF
vault {
  enabled = false
}

acl {
  enabled = true
}

ui {
  enabled = true
}

# OIDC Configuration
ui_config {
  enabled = true
  
  auth {
    enabled = true
    
    oidc {
      client_id = "nomad"
      authorization_endpoint = "https://api.nomadsilo.com/auth"
      token_endpoint = "https://api.nomadsilo.com/token"
      userinfo_endpoint = "https://api.nomadsilo.com/userinfo"
      jwks_endpoint = "https://api.nomadsilo.com/.well-known/jwks.json"
      
      scopes = ["openid", "email"]
      allowed_redirect_uris = ["https://nomad.nomadsilo.com/ui/settings/tokens"]
      discovery_url = "https://api.nomadsilo.com/.well-known/openid-configuration"
      
      claim_mappings = {
        email = "email"
      }
    }
  }
}
EOF

# Enable and start the service
systemctl daemon-reload
systemctl enable nomad
systemctl start nomad

# Setup AWS IAM OIDC integration
cat > ${NOMAD_DIR}/config/aws-oidc.hcl << EOF
plugin "nomad-workload-identity" {
  # this block configures the AWS workload identity provider
  enabled = true
  
  provider "aws" {
    # configure the AWS IAM OIDC provider URL
    oidc_provider_url = "https://api.nomadsilo.com"
    
    # path where the JWKS is served
    jwks_uri = "https://api.nomadsilo.com/.well-known/jwks.json"
    
    # AWS IAM audience (client ID)
    audience = "nomad"
    
    # default TTL for credentials
    default_ttl = "1h"
    
    # maximum allowed TTL
    max_ttl = "12h"
  }
}
EOF

# Configure hostname based on instance metadata
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
AWS_REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
HOSTNAME=$(aws ec2 describe-tags --region ${AWS_REGION} --filters "Name=resource-id,Values=${INSTANCE_ID}" "Name=key,Values=Name" --query 'Tags[0].Value' --output text)

# If we got a hostname, configure it
if [ ! -z "$HOSTNAME" ]; then
  echo "Setting hostname to ${HOSTNAME}"
  hostname ${HOSTNAME}
  echo ${HOSTNAME} > /etc/hostname
fi

echo "Nomad installation and configuration complete!"