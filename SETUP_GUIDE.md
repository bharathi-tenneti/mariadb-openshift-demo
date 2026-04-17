# CI/CD Setup Guide for MariaDB OpenShift Demo

This guide will help you set up the GitHub Actions CI/CD pipeline to automatically deploy your quotes application to OpenShift.

## Prerequisites

1. **GitHub Repository**: Your code should be in a GitHub repository
2. **OpenShift Cluster**: Access to an OpenShift cluster with admin privileges
3. **Container Registry**: A container registry account (Quay.io recommended)

## Step 1: Set up GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

Add the following secrets:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `REGISTRY_USERNAME` | Your container registry username | `myuser` |
| `REGISTRY_PASSWORD` | Your container registry password or token | `dckr_pat_xxxxx` |
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

## Step 2: Configure Container Registry

The workflow uses Quay.io by default. If you want to use a different registry, update the `REGISTRY_URL` in `.github/workflows/deploy-quotes-app.yml`.

### For Quay.io:
1. Create an organization or use your personal account
2. Generate a robot account token for GitHub Actions
3. Add the credentials as GitHub secrets

## Step 3: Push Changes to Trigger CI/CD

The workflow is configured to run on pushes to the `main` branch. To trigger the deployment:

1. Merge your PR to main
2. Or push directly to main (if you have permissions)

## What the Pipeline Does

1. **Build Stage**:
   - Builds Docker images for `quotesweb` (frontend) and `qotd-python` (backend)
   - Pushes images to your container registry

2. **Deploy Stage**:
   - Installs OpenShift CLI (`oc`)
   - Logs in to your OpenShift cluster
   - Creates the `quotes-app` namespace (if it doesn't exist)
   - Deploys MariaDB with persistent storage
   - Deploys the backend service (qotd-python)
   - Deploys the frontend (quotesweb)
   - Creates an OpenShift route to expose the frontend
   - Verifies all deployments are ready

## Monitoring the Deployment

1. **GitHub Actions**: Watch the workflow progress in the Actions tab
2. **OpenShift Console**: Check the `quotes-app` project for resources
3. **CLI**: Use `oc get pods -n quotes-app` to check pod status

## Troubleshooting

### Build Failures
- Check Dockerfile paths and build context
- Verify registry credentials are correct

### Deployment Failures
- Check OpenShift events: `oc get events -n quotes-app`
- Verify OpenShift token is valid and has sufficient permissions
- Check resource quotas in the namespace

### Database Connection Issues
- Ensure MariaDB pod is running and ready
- Verify database credentials in secrets
- Check network policies if using a restricted cluster

## Customization

### Change Namespace
Edit the `NAMESPACE` environment variable in the workflow file.

### Add More Environments
Create additional workflows for staging/production with different configurations.

### Use Helm Instead
Replace the `oc apply` commands with `helm upgrade --install` for more advanced deployment management.

## Security Best Practices

1. **Use specific image tags** instead of `latest` for production
2. **Enable branch protection** on main branch
3. **Use OIDC** for GitHub Actions to OpenShift authentication (more secure than tokens)
4. **Rotate secrets** regularly
5. **Scan images** for vulnerabilities before deployment

## Next Steps

After the initial deployment, you may want to:
- Set up monitoring and alerting
- Configure horizontal pod autoscaling
- Add backup solutions for the database
- Implement proper CI/CD with staging environments