const request = require('supertest');
const app = require('../src/app');

describe('FIAP Todo API', () => {

  describe('GET /health', () => {
    it('should return health status', async () => {
      const response = await request(app)
        .get('/health')
        .expect(200);

      expect(response.body.status).toBe('OK');
      expect(response.body.service).toBe('FIAP Todo API');
      expect(response.body.timestamp).toBeDefined();
      expect(response.body.version).toBeDefined();
    });
  });

  describe('GET /api/todos', () => {
    it('should return all todos', async () => {
      const response = await request(app)
        .get('/api/todos')
        .expect(200);

      expect(response.body.todos).toBeDefined();
      expect(response.body.total).toBeDefined();
      expect(Array.isArray(response.body.todos)).toBe(true);
    });

    it('should filter todos by completion status', async () => {
      const response = await request(app)
        .get('/api/todos?completed=false')
        .expect(200);

      expect(response.body.todos.every(todo => !todo.completed)).toBe(true);
    });

    it('should filter todos by priority', async () => {
      const response = await request(app)
        .get('/api/todos?priority=high')
        .expect(200);

      expect(response.body.todos.every(todo => todo.priority === 'high')).toBe(true);
    });

    it('should search todos by title', async () => {
      const response = await request(app)
        .get('/api/todos?search=FIAP')
        .expect(200);

      expect(response.body.todos.length).toBeGreaterThan(0);
    });
  });

  describe('POST /api/todos', () => {
    it('should create a new todo', async () => {
      const newTodo = {
        title: 'Test Todo',
        description: 'Test Description',
        priority: 'medium',
        category: 'work'
      };

      const response = await request(app)
        .post('/api/todos')
        .send(newTodo)
        .expect(201);

      expect(response.body.title).toBe(newTodo.title);
      expect(response.body.description).toBe(newTodo.description);
      expect(response.body.priority).toBe(newTodo.priority);
      expect(response.body.category).toBe(newTodo.category);
      expect(response.body.completed).toBe(false);
      expect(response.body.id).toBeDefined();
    });

    it('should return error for missing title', async () => {
      const invalidTodo = {
        description: 'Test Description'
      };

      const response = await request(app)
        .post('/api/todos')
        .send(invalidTodo)
        .expect(400);

      expect(response.body.error).toBe('Title is required');
    });

    it('should return error for invalid priority', async () => {
      const invalidTodo = {
        title: 'Test Todo',
        priority: 'invalid'
      };

      const response = await request(app)
        .post('/api/todos')
        .send(invalidTodo)
        .expect(400);

      expect(response.body.error).toBe('Priority must be low, medium, or high');
    });
  });

  describe('GET /api/todos/:id', () => {
    it('should return a specific todo', async () => {
      const response = await request(app)
        .get('/api/todos/1')
        .expect(200);

      expect(response.body.id).toBe(1);
      expect(response.body.title).toBeDefined();
    });

    it('should return 404 for non-existent todo', async () => {
      const response = await request(app)
        .get('/api/todos/999')
        .expect(404);

      expect(response.body.error).toBe('Todo not found');
    });
  });

  describe('PUT /api/todos/:id', () => {
    it('should update a todo', async () => {
      const updateData = {
        title: 'Updated Todo',
        completed: true
      };

      const response = await request(app)
        .put('/api/todos/1')
        .send(updateData)
        .expect(200);

      expect(response.body.title).toBe(updateData.title);
      expect(response.body.completed).toBe(updateData.completed);
      expect(response.body.updatedAt).toBeDefined();
    });

    it('should return 404 for non-existent todo', async () => {
      const response = await request(app)
        .put('/api/todos/999')
        .send({ title: 'Updated' })
        .expect(404);

      expect(response.body.error).toBe('Todo not found');
    });
  });

  describe('DELETE /api/todos/:id', () => {
    it('should delete a todo', async () => {
      // First create a todo to delete
      const createResponse = await request(app)
        .post('/api/todos')
        .send({ title: 'To be deleted' });

      const todoId = createResponse.body.id;

      const response = await request(app)
        .delete(`/api/todos/${todoId}`)
        .expect(200);

      expect(response.body.message).toBe('Todo deleted successfully');
      expect(response.body.todo.id).toBe(todoId);
    });

    it('should return 404 for non-existent todo', async () => {
      const response = await request(app)
        .delete('/api/todos/999')
        .expect(404);

      expect(response.body.error).toBe('Todo not found');
    });
  });

  describe('GET /api/stats', () => {
    it('should return statistics', async () => {
      const response = await request(app)
        .get('/api/stats')
        .expect(200);

      expect(response.body.total).toBeDefined();
      expect(response.body.completed).toBeDefined();
      expect(response.body.pending).toBeDefined();
      expect(response.body.byPriority).toBeDefined();
      expect(response.body.byCategory).toBeDefined();
    });
  });

  describe('Error handling', () => {
    it('should return 404 for non-existent routes', async () => {
      const response = await request(app)
        .get('/api/nonexistent')
        .expect(404);

      expect(response.body.error).toBe('Route not found');
    });
  });
});
