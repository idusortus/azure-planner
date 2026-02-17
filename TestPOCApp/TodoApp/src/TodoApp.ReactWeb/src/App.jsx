import { useState, useEffect } from 'react'
import './App.css'

// API Configuration
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5001/api/todos';

function App() {
  const [todos, setTodos] = useState([]);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [filter, setFilter] = useState('all');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Load todos on mount
  useEffect(() => {
    loadTodos();
  }, []);

  async function loadTodos() {
    try {
      setLoading(true);
      setError(null);
      const response = await fetch(API_BASE_URL);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const data = await response.json();
      setTodos(data);
    } catch (err) {
      console.error('Failed to load todos:', err);
      setError('Failed to connect to API. Make sure the backend is running.');
    } finally {
      setLoading(false);
    }
  }

  async function addTodo(e) {
    e.preventDefault();
    if (!title.trim()) return;

    try {
      const response = await fetch(API_BASE_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: title.trim(),
          description: description.trim() || null,
          isComplete: false
        })
      });

      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const newTodo = await response.json();
      setTodos([newTodo, ...todos]);
      setTitle('');
      setDescription('');
    } catch (err) {
      console.error('Failed to add todo:', err);
      alert('Failed to add todo. Please try again.');
    }
  }

  async function toggleTodo(id) {
    const todo = todos.find(t => t.id === id);
    if (!todo) return;

    try {
      const response = await fetch(`${API_BASE_URL}/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...todo,
          isComplete: !todo.isComplete
        })
      });

      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      
      setTodos(todos.map(t => t.id === id 
        ? { ...t, isComplete: !t.isComplete, completedAt: !t.isComplete ? new Date().toISOString() : null }
        : t
      ));
    } catch (err) {
      console.error('Failed to update todo:', err);
      alert('Failed to update todo. Please try again.');
    }
  }

  async function deleteTodo(id) {
    if (!confirm('Delete this todo?')) return;

    try {
      const response = await fetch(`${API_BASE_URL}/${id}`, {
        method: 'DELETE'
      });

      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      setTodos(todos.filter(t => t.id !== id));
    } catch (err) {
      console.error('Failed to delete todo:', err);
      alert('Failed to delete todo. Please try again.');
    }
  }

  // Filter todos
  const filteredTodos = todos.filter(todo => {
    if (filter === 'active') return !todo.isComplete;
    if (filter === 'completed') return todo.isComplete;
    return true;
  });

  const activeCount = todos.filter(t => !t.isComplete).length;

  return (
    <div className="container">
      <header>
        <h1>📝 TODO App</h1>
        <p className="subtitle">Azure POC - .NET Aspire + React</p>
      </header>

      <main>
        <form onSubmit={addTodo} className="add-form">
          <input
            type="text"
            placeholder="What needs to be done?"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            required
          />
          <input
            type="text"
            placeholder="Description (optional)"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
          />
          <button type="submit">Add</button>
        </form>

        <div className="filters">
          <button 
            className={filter === 'all' ? 'filter-btn active' : 'filter-btn'}
            onClick={() => setFilter('all')}
          >
            All
          </button>
          <button 
            className={filter === 'active' ? 'filter-btn active' : 'filter-btn'}
            onClick={() => setFilter('active')}
          >
            Active
          </button>
          <button 
            className={filter === 'completed' ? 'filter-btn active' : 'filter-btn'}
            onClick={() => setFilter('completed')}
          >
            Completed
          </button>
        </div>

        <div className="todo-list">
          {loading && <div className="loading">Loading...</div>}
          
          {error && (
            <div className="empty-state">
              <div className="icon">⚠️</div>
              <p>{error}</p>
              <button onClick={loadTodos} style={{marginTop: '16px', padding: '8px 16px'}}>
                Retry
              </button>
            </div>
          )}
          
          {!loading && !error && filteredTodos.length === 0 && (
            <div className="empty-state">
              <div className="icon">📋</div>
              <p>
                {filter === 'active' && 'No active todos. Time to relax! 🎉'}
                {filter === 'completed' && 'No completed todos yet. Keep going! 💪'}
                {filter === 'all' && 'No todos yet. Add one above! ☝️'}
              </p>
            </div>
          )}
          
          {!loading && !error && filteredTodos.map(todo => (
            <div key={todo.id} className={`todo-item ${todo.isComplete ? 'completed' : ''}`}>
              <input
                type="checkbox"
                className="todo-checkbox"
                checked={todo.isComplete}
                onChange={() => toggleTodo(todo.id)}
              />
              <div className="todo-content">
                <div className="todo-title">{todo.title}</div>
                {todo.description && <div className="todo-description">{todo.description}</div>}
                <div className="todo-date">
                  {new Date(todo.createdAt).toLocaleDateString('en-US', {
                    month: 'short',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                  })}
                </div>
              </div>
              <button 
                className="todo-delete" 
                onClick={() => deleteTodo(todo.id)}
                title="Delete"
              >
                🗑️
              </button>
            </div>
          ))}
        </div>

        <div className="status-bar">
          <span>{activeCount} active / {todos.length} total</span>
          <span className={`api-status ${error ? 'error' : 'connected'}`}>
            {error ? '❌ API Error' : '✅ Connected'}
          </span>
        </div>
      </main>

      <footer>
        <p>Built with ❤️ using .NET Aspire + Azure SQL Serverless + React</p>
      </footer>
    </div>
  )
}

export default App
