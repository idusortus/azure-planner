import { StatusBar } from 'expo-status-bar';
import { useState, useEffect } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TextInput,
  TouchableOpacity,
  FlatList,
  ActivityIndicator,
  Alert,
  SafeAreaView
} from 'react-native';

// API Configuration
const API_BASE_URL = 'https://todoapp-api.politeriver-ded1b871.centralus.azurecontainerapps.io/api/todos';

export default function App() {
  const [todos, setTodos] = useState([]);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');

  useEffect(() => {
    loadTodos();
  }, []);

  async function loadTodos() {
    try {
      setLoading(true);
      const response = await fetch(API_BASE_URL);
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const data = await response.json();
      setTodos(data);
    } catch (error) {
      console.error('Failed to load todos:', error);
      Alert.alert('Error', 'Failed to load todos. Please check your connection.');
    } finally {
      setLoading(false);
    }
  }

  async function addTodo() {
    if (!title.trim()) {
      Alert.alert('Error', 'Please enter a title');
      return;
    }

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
    } catch (error) {
      console.error('Failed to add todo:', error);
      Alert.alert('Error', 'Failed to add todo. Please try again.');
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
        ? { ...t, isComplete: !t.isComplete }
        : t
      ));
    } catch (error) {
      console.error('Failed to update todo:', error);
      Alert.alert('Error', 'Failed to update todo. Please try again.');
    }
  }

  async function deleteTodo(id) {
    Alert.alert(
      'Delete Todo',
      'Are you sure you want to delete this todo?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              const response = await fetch(`${API_BASE_URL}/${id}`, {
                method: 'DELETE'
              });

              if (!response.ok) throw new Error(`HTTP ${response.status}`);
              setTodos(todos.filter(t => t.id !== id));
            } catch (error) {
              console.error('Failed to delete todo:', error);
              Alert.alert('Error', 'Failed to delete todo. Please try again.');
            }
          }
        }
      ]
    );
  }

  const filteredTodos = todos.filter(todo => {
    if (filter === 'active') return !todo.isComplete;
    if (filter === 'completed') return todo.isComplete;
    return true;
  });

  const activeCount = todos.filter(t => !t.isComplete).length;

  const renderTodoItem = ({ item }) => (
    <View style={[styles.todoItem, item.isComplete && styles.todoItemCompleted]}>
      <TouchableOpacity
        style={styles.todoCheckbox}
        onPress={() => toggleTodo(item.id)}
      >
        <Text style={styles.checkbox}>{item.isComplete ? '✅' : '⬜'}</Text>
      </TouchableOpacity>
      
      <View style={styles.todoContent}>
        <Text style={[styles.todoTitle, item.isComplete && styles.todoTitleCompleted]}>
          {item.title}
        </Text>
        {item.description && (
          <Text style={styles.todoDescription}>{item.description}</Text>
        )}
        <Text style={styles.todoDate}>
          {new Date(item.createdAt).toLocaleDateString()}
        </Text>
      </View>
      
      <TouchableOpacity onPress={() => deleteTodo(item.id)} style={styles.deleteButton}>
        <Text style={styles.deleteButtonText}>🗑️</Text>
      </TouchableOpacity>
    </View>
  );

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar style="auto" />
      
      <View style={styles.header}>
        <Text style={styles.headerTitle}>📝 TODO App</Text>
        <Text style={styles.headerSubtitle}>React Native + Azure</Text>
      </View>

      <View style={styles.addForm}>
        <TextInput
          style={styles.input}
          placeholder="What needs to be done?"
          value={title}
          onChangeText={setTitle}
        />
        <TextInput
          style={styles.input}
          placeholder="Description (optional)"
          value={description}
          onChangeText={setDescription}
        />
        <TouchableOpacity style={styles.addButton} onPress={addTodo}>
          <Text style={styles.addButtonText}>Add</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.filters}>
        <TouchableOpacity
          style={[styles.filterButton, filter === 'all' && styles.filterButtonActive]}
          onPress={() => setFilter('all')}
        >
          <Text style={[styles.filterButtonText, filter === 'all' && styles.filterButtonTextActive]}>
            All
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.filterButton, filter === 'active' && styles.filterButtonActive]}
          onPress={() => setFilter('active')}
        >
          <Text style={[styles.filterButtonText, filter === 'active' && styles.filterButtonTextActive]}>
            Active
          </Text>
        </TouchableOpacity>
        <TouchableOpacity
          style={[styles.filterButton, filter === 'completed' && styles.filterButtonActive]}
          onPress={() => setFilter('completed')}
        >
          <Text style={[styles.filterButtonText, filter === 'completed' && styles.filterButtonTextActive]}>
            Completed
          </Text>
        </TouchableOpacity>
      </View>

      {loading ? (
        <View style={styles.loading}>
          <ActivityIndicator size="large" color="#0078d4" />
          <Text style={styles.loadingText}>Loading...</Text>
        </View>
      ) : (
        <FlatList
          data={filteredTodos}
          renderItem={renderTodoItem}
          keyExtractor={item => item.id.toString()}
          contentContainerStyle={styles.todoList}
          ListEmptyComponent={
            <View style={styles.emptyState}>
              <Text style={styles.emptyStateIcon}>📋</Text>
              <Text style={styles.emptyStateText}>
                {filter === 'active' && 'No active todos. Time to relax! 🎉'}
                {filter === 'completed' && 'No completed todos yet. Keep going! 💪'}
                {filter === 'all' && 'No todos yet. Add one above! ☝️'}
              </Text>
            </View>
          }
        />
      )}

      <View style={styles.statusBar}>
        <Text style={styles.statusText}>{activeCount} active / {todos.length} total</Text>
        <Text style={styles.apiStatus}>✅ Connected</Text>
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8f9fa',
  },
  header: {
    padding: 20,
    alignItems: 'center',
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#333',
  },
  headerSubtitle: {
    fontSize: 14,
    color: '#666',
    marginTop: 4,
  },
  addForm: {
    padding: 16,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  input: {
    borderWidth: 2,
    borderColor: '#e0e0e0',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    marginBottom: 10,
  },
  addButton: {
    backgroundColor: '#0078d4',
    padding: 14,
    borderRadius: 8,
    alignItems: 'center',
  },
  addButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  filters: {
    flexDirection: 'row',
    padding: 16,
    gap: 10,
  },
  filterButton: {
    flex: 1,
    padding: 10,
    backgroundColor: '#f5f5f5',
    borderRadius: 8,
    borderWidth: 2,
    borderColor: '#e0e0e0',
    alignItems: 'center',
  },
  filterButtonActive: {
    backgroundColor: '#0078d4',
    borderColor: '#0078d4',
  },
  filterButtonText: {
    fontSize: 14,
    color: '#333',
  },
  filterButtonTextActive: {
    color: '#fff',
    fontWeight: '600',
  },
  todoList: {
    padding: 16,
  },
  todoItem: {
    flexDirection: 'row',
    padding: 16,
    backgroundColor: '#fff',
    borderRadius: 8,
    borderWidth: 2,
    borderColor: '#e0e0e0',
    marginBottom: 12,
    alignItems: 'flex-start',
  },
  todoItemCompleted: {
    opacity: 0.6,
  },
  todoCheckbox: {
    marginRight: 12,
  },
  checkbox: {
    fontSize: 20,
  },
  todoContent: {
    flex: 1,
  },
  todoTitle: {
    fontSize: 16,
    fontWeight: '500',
    color: '#333',
    marginBottom: 4,
  },
  todoTitleCompleted: {
    textDecorationLine: 'line-through',
  },
  todoDescription: {
    fontSize: 14,
    color: '#666',
    marginBottom: 8,
  },
  todoDate: {
    fontSize: 12,
    color: '#999',
  },
  deleteButton: {
    padding: 4,
  },
  deleteButtonText: {
    fontSize: 18,
  },
  emptyState: {
    alignItems: 'center',
    padding: 60,
  },
  emptyStateIcon: {
    fontSize: 60,
    marginBottom: 16,
  },
  emptyStateText: {
    fontSize: 16,
    color: '#666',
    textAlign: 'center',
  },
  loading: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 12,
    fontSize: 16,
    color: '#666',
  },
  statusBar: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    padding: 12,
    backgroundColor: '#f5f5f5',
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
  },
  statusText: {
    fontSize: 14,
    color: '#666',
  },
  apiStatus: {
    fontSize: 14,
    color: '#155724',
  },
});
