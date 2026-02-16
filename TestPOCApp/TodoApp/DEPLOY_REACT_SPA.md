# Deploying React SPA to Azure Static Web Apps

This guide shows how to deploy the React SPA frontend to Azure Static Web Apps.

## Prerequisites

- Azure CLI installed and logged in (`az login`)
- Node.js 18+ installed
- Azure Static Web Apps deployment token (from infrastructure setup)

## Option 1: Using Azure CLI

### 1. Build the React App

```bash
cd TestPOCApp/TodoApp/src/TodoApp.ReactWeb

# Build for production
npm run build
```

This creates a `dist/` folder with optimized static files.

### 2. Deploy to Static Web App

```bash
# Install Static Web Apps CLI
npm install -g @azure/static-web-apps-cli

# Deploy
cd dist
swa deploy . \
  --deployment-token "YOUR_DEPLOYMENT_TOKEN" \
  --app-location "." \
  --output-location "."
```

## Option 2: Using npm Package

### 1. Install SWA CLI in Project

```bash
cd TestPOCApp/TodoApp/src/TodoApp.ReactWeb
npm install --save-dev @azure/static-web-apps-cli
```

### 2. Add Deploy Script to package.json

```json
{
  "scripts": {
    "build": "vite build",
    "deploy": "npm run build && cd dist && swa deploy ."
  }
}
```

### 3. Create .env.production

```bash
# Set production API URL
echo "VITE_API_URL=https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io/api/todos" > .env.production
```

### 4. Deploy

```bash
npm run deploy
```

## Option 3: GitHub Actions (Automated)

Azure Static Web Apps can automatically deploy when you push to GitHub.

### 1. Get Deployment Token

```bash
az staticwebapp secrets list \
  --name todo-app-web \
  --resource-group todo-app \
  --query properties.apiKey -o tsv
```

### 2. Create GitHub Workflow

Create `.github/workflows/deploy-react-spa.yml`:

```yaml
name: Deploy React SPA

on:
  push:
    branches: [main]
    paths:
      - 'TestPOCApp/TodoApp/src/TodoApp.ReactWeb/**'

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - name: Install dependencies
        run: |
          cd TestPOCApp/TodoApp/src/TodoApp.ReactWeb
          npm ci
      
      - name: Build
        run: |
          cd TestPOCApp/TodoApp/src/TodoApp.ReactWeb
          npm run build
        env:
          VITE_API_URL: https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io/api/todos
      
      - name: Deploy to Azure Static Web Apps
        uses: Azure/static-web-apps-deploy@v1
        with:
          azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
          repo_token: ${{ secrets.GITHUB_TOKEN }}
          action: "upload"
          app_location: "TestPOCApp/TodoApp/src/TodoApp.ReactWeb/dist"
          skip_app_build: true
```

### 3. Add Secret to GitHub

1. Go to GitHub repository settings
2. Secrets and variables → Actions
3. Add secret: `AZURE_STATIC_WEB_APPS_API_TOKEN`
4. Paste the deployment token

## Configuration for Production

### Environment Variables

The React app uses Vite's environment variables:

**Development (.env.local):**
```bash
VITE_API_URL=http://localhost:5001/api/todos
```

**Production (.env.production):**
```bash
VITE_API_URL=https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io/api/todos
```

### Static Web Apps Configuration

Create `staticwebapp.config.json` in `dist/` (or root):

```json
{
  "navigationFallback": {
    "rewrite": "/index.html",
    "exclude": ["/assets/*", "/*.js", "/*.css"]
  },
  "routes": [
    {
      "route": "/api/*",
      "allowedRoles": ["anonymous"]
    }
  ],
  "responseOverrides": {
    "404": {
      "rewrite": "/index.html"
    }
  }
}
```

## Verify Deployment

1. Check Static Web App URL:
   ```bash
   az staticwebapp show \
     --name todo-app-web \
     --resource-group todo-app \
     --query defaultHostname -o tsv
   ```

2. Visit the URL in browser
3. Test CRUD operations
4. Check browser console for errors

## Troubleshooting

### CORS Errors

Ensure API has CORS configured for Static Web App domain:

```csharp
// In TodoApp.Api/Program.cs
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins(
            "https://localhost:3000",
            "https://*.azurestaticapps.net")
        .AllowAnyMethod()
        .AllowAnyHeader();
    });
});
```

### Build Fails

```bash
# Clear node_modules and rebuild
rm -rf node_modules package-lock.json
npm install
npm run build
```

### API Not Connecting

1. Check `VITE_API_URL` in build environment
2. Verify API is running (visit API URL in browser)
3. Check browser console for CORS errors
4. Ensure API allows requests from Static Web App domain

## Cost

Azure Static Web Apps Free Tier:
- **Cost**: $0/month
- **Bandwidth**: 100 GB/month
- **Custom domains**: Included
- **SSL**: Free (auto-provisioned)

Perfect for POC and small production apps!
