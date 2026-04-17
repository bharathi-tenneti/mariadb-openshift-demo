# CI/CD Setup Guide for MariaDB OpenShift Demo

This guide will help you set up the GitHub Actions CI/CD pipeline to automatically deploy your quotes application to OpenShift.

## Overview

This pipeline deploys a pre-built quotes application to OpenShift using existing container images from Quay.io. No building is required - the workflow simply deploys the application components to your OpenShift cluster.

## Prerequisites

1. **GitHub Repository**: Your code should be in a GitHub repository
2. **OpenShift Cluster**: Access to an OpenShift cluster with admin privileges

## Step 1: Set up GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Add the following secrets:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `OPENSHIFT_SERVER` | Your OpenShift API server URL | `https://api.myopenshift.com:6443` |
| `OPENSHIFT_TOKEN` | OpenShift service account token | `sha256~xxxxx` |
| `DATABASE_PASSWORD` | Password for the MariaDB database | `MySecurePassword123!` |

### Getting OpenShift Token

1. Log in to your OpenShift cluster
2. Create a service account with appropriate permissions:
   ```bash
   oc new-project quotes-app
   oc create serviceaccount github-actions
   oc adm policy add-cluster-role-to-user admin -z github-actions -n quotes-app
   ```
3. Get the token:
   ```bash
   oc create token github-actions -n quotes-app
   ```

## Step 2: Push Changes to Trigger CI/CD

The workflow is configured to run on pushes to the `main` branch. To trigger the deployment:

1. Merge your PR to main
2. Or push directly to main (if you have permissions)

## What the Pipeline Does

The deployment pipeline:

1. **Checkout Code**: Clones your repository
2. **Install OpenShift CLI**: Downloads and installs the `oc` command-line tool
3. **Log in to OpenShift**: Authenticates with your OpenShift cluster
4. **Create Namespace**: Creates the `quotes-app` project (if it doesn't exist)
5. **Deploy MariaDB**: 
   - Creates database secret with credentials
   - Deploys MariaDB 10.6 with resource limits
   - Creates service for database access
6. **Deploy Backend (qotd-python)**:
   - Uses pre-built image: `quay.io/donschenck/qotd-python:v1`
   - Configures database connection via environment variables
   - Creates service for frontend access
7. **Deploy Frontend (quotesweb)**:
   - Uses pre-built image: `quay.io/donschenck/quotesweb:v1`
   - Configures backend URL
   - Creates service and route for external access
8. **Verify Deployment**: Waits for all deployments to be ready

## Monitoring the Deployment

1. **GitHub Actions**: Watch the workflow progress in the Actions tab
2. **OpenShift Console**: Check the `quotes-app` project for resources
3. **CLI**: Use `oc get pods -n quotes-app` to check pod status

## Troubleshooting

### Deployment Failures
- Check OpenShift events: `oc get events -n quotes-app`
- Verify OpenShift token is valid and has sufficient permissions
- Check resource quotas in the namespace

### Database Connection Issues
- Ensure MariaDB pod is running and ready
- Verify database credentials in secrets
- Check network policies if using a restricted cluster

### Image Pull Issues
- Verify the Quay.io images are accessible
- Check if your OpenShift cluster can reach external registries

## Customization

### Change Namespace
Edit the `NAMESPACE` environment variable in the workflow file.

### Use Different Images
Update the image references in the workflow file:
- `quay.io/donschenck/quotesweb:v1` for frontend
- `quay.io/donschenck/qotd-python:v1` for backend
- `mariadb:10.6` for database

### Add More Environments
Create additional workflows for staging/production with different configurations.

## Security Best Practices

1. **Enable branch protection** on main branch
2. **Use OIDC** for GitHub Actions to OpenShift authentication (more secure than tokens)
3. **Rotate secrets** regularly
4. **Use specific image tags** instead of `latest` for production
5. **Scan images** for vulnerabilities before deployment

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   quotesweb     │───▶│   qotd-python   │───▶│    MariaDB      │
│   (frontend)    │    │    (backend)    │    │   (database)    │
│   Port 3000     │    │    Port 8080    │    │    Port 3306    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │
        ▼
┌─────────────────┐
│  OpenShift Route │
│   (HTTPS)       │
└─────────────────┘
```

## Next Steps

After the initial deployment, you may want to:
- Set up monitoring and alerting
- Configure horizontal pod autoscaling
- Add backup solutions for the database
- Implement proper CI/CD with staging environments
- Set up persistent storage for the database