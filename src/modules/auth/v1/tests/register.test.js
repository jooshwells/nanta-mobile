import express from 'express';
import request from 'supertest';
import mongoose from 'mongoose';
import { describe, it, beforeAll, afterAll, afterEach, expect } from 'vitest';
import { normalize_response, normalize_system_error_response, normalize_response_404 } from '../../../../custom.middleware.js';

import { rate_limit, validate_registration } from '../auth.middleware.js';
import { register_user } from '../auth.controller.js';
import User from '../auth.model.js';

let app;

describe('POST /register', {}, () => {
  beforeAll(async () => {
    app = express();
    app.use(normalize_response);
    app.use(express.json());
    app.post('/api/auth/register', rate_limit, validate_registration, register_user);

    app.use(normalize_response_404);

    await mongoose.connect('mongodb://mongo:27017/auth_test');
  });

  afterEach(async () => {
    await User.deleteMany({});
  });

  afterAll(async () => {
    await mongoose.connection.close(true);
  });

  it('should register a new user successfully', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        first_name: 'John',
        last_name: 'Doe',
        email: 'john@example.com',
        password: 'password123',
        confirm_password: 'password123'
      });

    expect(response.statusCode).toBe(201);
    expect(response.body).toHaveProperty('data.user.email', 'john@example.com');
    expect(response.body).toHaveProperty('message', 'User registered!');
  });

  it('should fail if email is missing', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        first_name: 'Jane',
        last_name: 'Doe',
        password: 'password123',
        confirm_password: 'password123'
      });
      console.log('BODY:', response.body);
    expect(response.statusCode).toBe(400);
    expect(response.body).toHaveProperty('errors.email', 'Please enter a valid email');
  });

  it('should fail if email format is invalid', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        first_name: 'Jane',
        last_name: 'Doe',
        email: 'invalidemail',
        password: 'password123',
        confirm_password: 'password123'
      });

    expect(response.statusCode).toBe(400);
    expect(response.body).toHaveProperty('errors.email', 'Please enter a valid email');
  });

  it('should fail if password is too short', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        first_name: 'Jake',
        last_name: 'Doe',
        email: 'jake@example.com',
        password: '123',
        confirm_password: '123'
      });

    expect(response.statusCode).toBe(400);
    // expect(response.body).toHaveProperty('data.password', 'Password must be at least 8 characters');
  });

  it('should fail if passwords do not match', async () => {
    const response = await request(app)
      .post('/api/auth/register')
      .send({
        first_name: 'Amy',
        last_name: 'Smith',
        email: 'amy@example.com',
        password: 'password123',
        confirm_password: 'different'
      });

    expect(response.statusCode).toBe(400);
    expect(response.body).toHaveProperty('errors.confirm_password', 'Passwords do not match');
  });

  it('should fail if email is already registered', async () => {
    await User.create({
      first_name: 'Existing',
      last_name: 'User',
      email: 'existing@example.com',
      password: 'password123'
    });

    const response = await request(app)
      .post('/api/auth/register')
      .send({
        first_name: 'John',
        last_name: 'Doe',
        email: 'existing@example.com',
        password: 'password123',
        confirm_password: 'password123'
      });

    expect(response.statusCode).toBe(400);
    expect(response.body).toHaveProperty('errors.email', 'Email is already registered');
  });

  it('should block requests after hitting rate limit', async () => {
    for (let i = 0; i < 20; i++) {
      await request(app)
        .post('/api/auth/register')
        .send({
          first_name: 'Rate',
          last_name: 'Test',
          email: `rate${i}@example.com`,
          password: 'password123',
          confirm_password: 'password123'
        });
    }

    const response = await request(app)
      .post('/api/auth/register')
      .send({
        first_name: 'Rate',
        last_name: 'Limit',
        email: 'ratelimit@example.com',
        password: 'password123',
        confirm_password: 'password123'
      });

    expect(response.statusCode).toBe(429);
    expect(response.body).toHaveProperty('error', 'Too many requests, please try again later.');
  });
});
