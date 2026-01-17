---
applyTo: "**/wwwroot/**"
---

# JavaScript Frontend Instructions

**Purpose**: Instructions for GitHub Copilot when developing JavaScript SPA frontends for Aspire POC applications

## Location

Frontend files go in: `src/{PocName}.Web/wwwroot/`

## Structure

```
wwwroot/
  index.html          # Entry point
  css/
    styles.css        # Main stylesheet
  js/
    app.js            # Application logic
    api.js            # API client (optional)
  assets/
    images/           # Static images
```

## API Communication Pattern

**Recommended pattern** (environment-aware):
```javascript
// API base URL - works locally and in Azure
const apiBaseUrl = window.ENV?.API_URL || 'https://localhost:7001';

// Generic fetch wrapper
async function apiRequest(endpoint, options = {}) {
    const url = `${apiBaseUrl}${endpoint}`;
    const response = await fetch(url, {
        headers: {
            'Content-Type': 'application/json',
            ...options.headers
        },
        ...options
    });
    
    if (!response.ok) {
        throw new Error(`API Error: ${response.status}`);
    }
    
    return response.json();
}

// Example usage
async function getItems() {
    return apiRequest('/api/items');
}

async function createItem(data) {
    return apiRequest('/api/items', {
        method: 'POST',
        body: JSON.stringify(data)
    });
}

async function updateItem(id, data) {
    return apiRequest(`/api/items/${id}`, {
        method: 'PUT',
        body: JSON.stringify(data)
    });
}

async function deleteItem(id) {
    return apiRequest(`/api/items/${id}`, {
        method: 'DELETE'
    });
}
```

## HTML Template

**index.html**:
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{PocName}</title>
    <link rel="stylesheet" href="css/styles.css">
</head>
<body>
    <div id="app">
        <header>
            <h1>{PocName}</h1>
        </header>
        <main>
            <!-- Content here -->
        </main>
    </div>
    
    <!-- Environment configuration (injected in production) -->
    <script>
        window.ENV = window.ENV || {};
    </script>
    <script src="js/app.js"></script>
</body>
</html>
```

## CSS Guidelines

**styles.css**:
```css
/* Use CSS variables for theming */
:root {
    --primary-color: #0078d4;
    --background-color: #f5f5f5;
    --text-color: #333;
    --border-color: #ddd;
    --success-color: #107c10;
    --error-color: #d13438;
}

/* Mobile-first responsive design */
* {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background-color: var(--background-color);
    color: var(--text-color);
    line-height: 1.6;
}

/* Container */
#app {
    max-width: 800px;
    margin: 0 auto;
    padding: 20px;
}
```

## Error Handling

```javascript
// Display errors to user
function showError(message) {
    const errorDiv = document.getElementById('error-message');
    errorDiv.textContent = message;
    errorDiv.style.display = 'block';
    
    setTimeout(() => {
        errorDiv.style.display = 'none';
    }, 5000);
}

// Wrap API calls with error handling
async function safeApiCall(apiFunction, ...args) {
    try {
        return await apiFunction(...args);
    } catch (error) {
        console.error('API Error:', error);
        showError(error.message || 'An error occurred');
        throw error;
    }
}
```

## Loading States

```javascript
function setLoading(isLoading) {
    const loadingIndicator = document.getElementById('loading');
    loadingIndicator.style.display = isLoading ? 'block' : 'none';
}

// Usage
async function loadData() {
    setLoading(true);
    try {
        const data = await getItems();
        renderItems(data);
    } finally {
        setLoading(false);
    }
}
```

## DOM Manipulation Pattern

```javascript
// Render list of items
function renderItems(items) {
    const container = document.getElementById('items-list');
    container.innerHTML = items.map(item => `
        <div class="item" data-id="${item.id}">
            <span class="item-title">${escapeHtml(item.title)}</span>
            <button onclick="deleteItem(${item.id})">Delete</button>
        </div>
    `).join('');
}

// Escape HTML to prevent XSS
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
```

## Form Handling

```javascript
// Handle form submission
document.getElementById('item-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const formData = new FormData(e.target);
    const data = Object.fromEntries(formData);
    
    await createItem(data);
    e.target.reset();
    await loadData();
});
```

## Technology Preference

- **Vanilla JavaScript** preferred for POC simplicity
- No build step required
- No framework dependencies
- Direct DOM manipulation
- Modern ES6+ syntax (async/await, arrow functions, template literals)

## Deployment Notes

- Files are served as static content
- No server-side rendering
- API URL injected via environment in production
- Works with Azure Static Web Apps (Free tier)
