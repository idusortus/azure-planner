/**
 * TODO App - Vanilla JavaScript Frontend
 * Connects to the .NET Aspire API
 */

// Configuration - will be updated to use Aspire service discovery
const CONFIG = {
    // API URL is injected via /config.js endpoint from the Web server
    // This allows Aspire to provide the correct service URL
    apiBaseUrl: window.API_BASE_URL || 'http://localhost:5001/api/todos'
};

// State
let todos = [];
let currentFilter = 'all';

// DOM Elements
const todoList = document.getElementById('todo-list');
const addForm = document.getElementById('add-todo-form');
const titleInput = document.getElementById('todo-title');
const descriptionInput = document.getElementById('todo-description');
const itemCount = document.getElementById('item-count');
const apiStatus = document.getElementById('api-status');
const filterButtons = document.querySelectorAll('.filter-btn');

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    // Get API URL from Aspire service discovery (passed via script tag or env)
    discoverApiUrl();
    
    // Load initial data
    loadTodos();
    
    // Set up event listeners
    addForm.addEventListener('submit', handleAddTodo);
    filterButtons.forEach(btn => {
        btn.addEventListener('click', () => setFilter(btn.dataset.filter));
    });
});

/**
 * Discover the API URL from Aspire service discovery
 * The URL is injected via /config.js which is served by the Web backend
 */
function discoverApiUrl() {
    console.log('API Base URL:', CONFIG.apiBaseUrl);
}

/**
 * Load all todos from the API
 */
async function loadTodos() {
    showLoading();
    
    try {
        const response = await fetch(CONFIG.apiBaseUrl);
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        
        todos = await response.json();
        setApiStatus('connected', '✅ Connected');
        renderTodos();
    } catch (error) {
        console.error('Failed to load todos:', error);
        setApiStatus('error', '❌ API Error');
        showError('Failed to connect to API. Make sure the Aspire app is running.');
    }
}

/**
 * Add a new todo
 */
async function handleAddTodo(e) {
    e.preventDefault();
    
    const title = titleInput.value.trim();
    const description = descriptionInput.value.trim();
    
    if (!title) return;
    
    const newTodo = {
        title,
        description: description || null,
        isComplete: false
    };
    
    try {
        const response = await fetch(CONFIG.apiBaseUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(newTodo)
        });
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        
        const created = await response.json();
        todos.unshift(created);
        renderTodos();
        
        // Clear form
        titleInput.value = '';
        descriptionInput.value = '';
        titleInput.focus();
    } catch (error) {
        console.error('Failed to add todo:', error);
        alert('Failed to add todo. Please try again.');
    }
}

/**
 * Toggle todo completion status
 */
async function toggleTodo(id) {
    const todo = todos.find(t => t.id === id);
    if (!todo) return;
    
    const updatedTodo = {
        ...todo,
        isComplete: !todo.isComplete
    };
    
    try {
        const response = await fetch(`${CONFIG.apiBaseUrl}/${id}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(updatedTodo)
        });
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        
        // Update local state
        todo.isComplete = updatedTodo.isComplete;
        todo.completedAt = todo.isComplete ? new Date().toISOString() : null;
        renderTodos();
    } catch (error) {
        console.error('Failed to update todo:', error);
        alert('Failed to update todo. Please try again.');
    }
}

/**
 * Delete a todo
 */
async function deleteTodo(id) {
    if (!confirm('Delete this todo?')) return;
    
    try {
        const response = await fetch(`${CONFIG.apiBaseUrl}/${id}`, {
            method: 'DELETE'
        });
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        
        // Remove from local state
        todos = todos.filter(t => t.id !== id);
        renderTodos();
    } catch (error) {
        console.error('Failed to delete todo:', error);
        alert('Failed to delete todo. Please try again.');
    }
}

/**
 * Set the current filter
 */
function setFilter(filter) {
    currentFilter = filter;
    
    // Update button states
    filterButtons.forEach(btn => {
        btn.classList.toggle('active', btn.dataset.filter === filter);
    });
    
    renderTodos();
}

/**
 * Render todos based on current filter
 */
function renderTodos() {
    const filtered = todos.filter(todo => {
        if (currentFilter === 'active') return !todo.isComplete;
        if (currentFilter === 'completed') return todo.isComplete;
        return true;
    });
    
    if (filtered.length === 0) {
        todoList.innerHTML = `
            <div class="empty-state">
                <div class="icon">📋</div>
                <p>${getEmptyMessage()}</p>
            </div>
        `;
    } else {
        todoList.innerHTML = filtered.map(todo => `
            <div class="todo-item ${todo.isComplete ? 'completed' : ''}" data-id="${todo.id}">
                <input 
                    type="checkbox" 
                    class="todo-checkbox" 
                    ${todo.isComplete ? 'checked' : ''}
                    onchange="toggleTodo(${todo.id})"
                >
                <div class="todo-content">
                    <div class="todo-title">${escapeHtml(todo.title)}</div>
                    ${todo.description ? `<div class="todo-description">${escapeHtml(todo.description)}</div>` : ''}
                    <div class="todo-date">${formatDate(todo.createdAt)}</div>
                </div>
                <button class="todo-delete" onclick="deleteTodo(${todo.id})" title="Delete">🗑️</button>
            </div>
        `).join('');
    }
    
    updateItemCount();
}

/**
 * Get empty state message based on filter
 */
function getEmptyMessage() {
    switch (currentFilter) {
        case 'active':
            return 'No active todos. Time to relax! 🎉';
        case 'completed':
            return 'No completed todos yet. Keep going! 💪';
        default:
            return 'No todos yet. Add one above! ☝️';
    }
}

/**
 * Update the item count display
 */
function updateItemCount() {
    const active = todos.filter(t => !t.isComplete).length;
    const total = todos.length;
    itemCount.textContent = `${active} active / ${total} total`;
}

/**
 * Set API status indicator
 */
function setApiStatus(status, text) {
    apiStatus.className = `api-status ${status}`;
    apiStatus.textContent = text;
}

/**
 * Show loading state
 */
function showLoading() {
    todoList.innerHTML = '<div class="loading"></div>';
}

/**
 * Show error message
 */
function showError(message) {
    todoList.innerHTML = `
        <div class="empty-state">
            <div class="icon">⚠️</div>
            <p>${message}</p>
            <button onclick="loadTodos()" style="margin-top: 16px; padding: 8px 16px; cursor: pointer;">Retry</button>
        </div>
    `;
}

/**
 * Format date for display
 */
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

/**
 * Escape HTML to prevent XSS
 */
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
