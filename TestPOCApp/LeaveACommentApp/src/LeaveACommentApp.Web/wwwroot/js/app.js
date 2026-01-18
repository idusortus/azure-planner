// Username generator - Adverb + Noun combinations
const ADVERBS = [
    'Swiftly', 'Quietly', 'Boldly', 'Gently', 'Fiercely', 
    'Calmly', 'Eagerly', 'Happily', 'Lazily', 'Proudly',
    'Silently', 'Wildly', 'Wisely', 'Bravely', 'Cleverly',
    'Dreamily', 'Gracefully', 'Hastily', 'Joyfully', 'Kindly',
    'Merrily', 'Neatly', 'Oddly', 'Politely', 'Quickly'
];

const NOUNS = [
    'Penguin', 'Dragon', 'Phoenix', 'Unicorn', 'Panda',
    'Tiger', 'Falcon', 'Dolphin', 'Wolf', 'Bear',
    'Eagle', 'Owl', 'Fox', 'Raven', 'Shark',
    'Koala', 'Otter', 'Lynx', 'Hawk', 'Whale',
    'Badger', 'Jaguar', 'Cobra', 'Mantis', 'Heron'
];

// Generate random username
function generateUsername() {
    const adverb = ADVERBS[Math.floor(Math.random() * ADVERBS.length)];
    const noun = NOUNS[Math.floor(Math.random() * NOUNS.length)];
    return `${adverb}${noun}`;
}

// Get or create username from localStorage
function getUsername() {
    let username = localStorage.getItem('commentUsername');
    if (!username) {
        username = generateUsername();
        localStorage.setItem('commentUsername', username);
    }
    return username;
}

// Format timestamp to HH:MM:SS
function formatTime(dateString) {
    const date = new Date(dateString);
    return date.toLocaleTimeString('en-US', { 
        hour: '2-digit', 
        minute: '2-digit', 
        second: '2-digit',
        hour12: false 
    });
}

// State
let currentUsername = getUsername();
const apiUrl = window.API_BASE_URL || '/api/comments';

// DOM Elements
const usernameSpan = document.getElementById('username');
const commentForm = document.getElementById('comment-form');
const messageInput = document.getElementById('message');
const charCurrent = document.getElementById('char-current');
const refreshBtn = document.getElementById('refresh-btn');
const commentsList = document.getElementById('comments-list');
const loadingDiv = document.getElementById('loading');
const emptyState = document.getElementById('empty-state');

// Initialize
document.addEventListener('DOMContentLoaded', () => {
    usernameSpan.textContent = currentUsername;
    loadComments();
    
    // Character counter
    messageInput.addEventListener('input', updateCharCount);
    
    // Form submit
    commentForm.addEventListener('submit', handleSubmit);
    
    // Refresh button
    refreshBtn.addEventListener('click', loadComments);
});

// Update character count
function updateCharCount() {
    const count = messageInput.value.length;
    charCurrent.textContent = count;
    
    const charCountSpan = document.querySelector('.char-count');
    charCountSpan.classList.remove('warning', 'danger');
    
    if (count >= 240) {
        charCountSpan.classList.add('danger');
    } else if (count >= 200) {
        charCountSpan.classList.add('warning');
    }
}

// Load comments from API
async function loadComments() {
    loadingDiv.style.display = 'flex';
    emptyState.style.display = 'none';
    commentsList.innerHTML = '';
    
    try {
        const response = await fetch(apiUrl);
        if (!response.ok) throw new Error('Failed to load comments');
        
        const comments = await response.json();
        
        loadingDiv.style.display = 'none';
        
        if (comments.length === 0) {
            emptyState.style.display = 'block';
            return;
        }
        
        comments.forEach(comment => {
            commentsList.appendChild(createCommentElement(comment));
        });
    } catch (error) {
        console.error('Error loading comments:', error);
        loadingDiv.innerHTML = '❌ Failed to load comments. <button onclick="loadComments()">Retry</button>';
    }
}

// Create comment DOM element
function createCommentElement(comment) {
    const div = document.createElement('div');
    div.className = 'comment';
    div.dataset.id = comment.id;
    
    // Mark own comments
    if (comment.username === currentUsername) {
        div.classList.add('own-comment');
    }
    
    div.innerHTML = `
        <div class="comment-header">
            <span class="comment-username">${escapeHtml(comment.username)}</span>
            <span class="comment-time">${formatTime(comment.createdAt)}</span>
        </div>
        <p class="comment-message">${escapeHtml(comment.message)}</p>
        ${comment.username === currentUsername ? 
            `<button class="comment-delete" onclick="deleteComment(${comment.id})" title="Delete">🗑️</button>` 
            : ''}
    `;
    
    return div;
}

// Handle form submission
async function handleSubmit(e) {
    e.preventDefault();
    
    const message = messageInput.value.trim();
    if (!message) return;
    
    const submitBtn = commentForm.querySelector('button[type="submit"]');
    submitBtn.disabled = true;
    submitBtn.textContent = 'Posting...';
    
    try {
        const response = await fetch(apiUrl, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                username: currentUsername,
                message: message
            })
        });
        
        if (!response.ok) {
            const error = await response.text();
            throw new Error(error || 'Failed to post comment');
        }
        
        messageInput.value = '';
        updateCharCount();
        await loadComments();
        
    } catch (error) {
        console.error('Error posting comment:', error);
        alert('Failed to post comment: ' + error.message);
    } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = 'Post Comment';
    }
}

// Delete comment
async function deleteComment(id) {
    if (!confirm('Delete this comment?')) return;
    
    try {
        const response = await fetch(`${apiUrl}/${id}?username=${encodeURIComponent(currentUsername)}`, {
            method: 'DELETE'
        });
        
        if (!response.ok) {
            throw new Error('Failed to delete comment');
        }
        
        // Remove from DOM with animation
        const commentEl = document.querySelector(`[data-id="${id}"]`);
        if (commentEl) {
            commentEl.style.opacity = '0';
            commentEl.style.transform = 'translateX(-100%)';
            setTimeout(() => commentEl.remove(), 300);
        }
        
    } catch (error) {
        console.error('Error deleting comment:', error);
        alert('Failed to delete comment');
    }
}

// Escape HTML to prevent XSS
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}
