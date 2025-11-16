import mongoose from 'mongoose';
import { describe, it, beforeAll, afterAll, afterEach, expect } from 'vitest';
import request from "supertest";
import app from "../../../../app.js";
import User from '../auth.model.js';
import bcrypt from 'bcryptjs';


describe("/api/auth/login", () => {
    beforeAll(async () => {
        try 
        {
            if (process.env.NODE_ENV === "production")
            {
                await mongoose.connect(process.env.MONGO_URI);
                console.log("Connected to production database `" + process.env.MONGO_URI + "`. Ready for testing!");
            }
            else
            {
                await mongoose.connect("mongodb://mongo:27017/test");
                // await mongoose.connect("mongodb://mongo:27017/login-test");
                console.log("Connected to test database `mongodb://mongo:27017/test`. Ready for testing!");
            }
        } 
        catch (error) 
        {
            console.error(error);
            process.exit(1);
        }

        await User.deleteMany();

        /* Direct database insert */
        const user = await User.create({
            first_name: "John",
            last_name: "Doe",
            email: "johndoe@example.com",
            password: await bcrypt.hash("password123", 10)
        });
    });

    afterAll(async () => {
        await User.deleteMany();
    });

    it("log in user | successful login (ok)", async () => {
        const response = await request(app)
            .post("/api/auth/login")
            .send({
                email: "johndoe@example.com",
                password: "password123",
            });

        expect(response.statusCode).toBe(200);
        expect("User logged in successfully!");
    });

    it("log in user | wrong email (err)", async () => {
        const response = await request(app)
            .post("/api/auth/login")
            .send({
                email: "wrongemail@example.com",
                password: "password123",
            });

            expect(response.statusCode).toBe(400);
            expect(response.body.errors.login).toHaveProperty("msg", "Invalid email or password");
    });

    it("log in user | missing email (err)", async () => {
        const response = await request(app)
            .post("/api/auth/login")
            .send({
                // email: "johndoe@example.com",
                password: "password123",
            });

            expect(response.statusCode).toBe(400);
            expect(response.body.errors.login).toHaveProperty("msg", "Invalid email or password");
    });

    it("log in user | wrong password (err)", async () => {
        const response = await request(app)
            .post("/api/auth/login")
            .send({
                email: "johndoe@example.com",
                password: "wrongpassword",
            });

            expect(response.statusCode).toBe(400);
            expect(response.body.errors.login).toHaveProperty("msg", "Invalid email or password");
    });

    it("log in user | missing password (err)", async () => {
        const response = await request(app)
            .post("/api/auth/login")
            .send({
                email: "johndoe@example.com",
                // password: "wrongpassword",
            });

            expect(response.statusCode).toBe(400);
            expect(response.body.errors.login).toHaveProperty("msg", "Invalid email or password");
    });

    it("log in user | wrong email and password (err)", async () => {
        const response = await request(app)
            .post("/api/auth/login")
            .send({
                email: "wrongemail@example.com",
                password: "wrongpassword",
            });

            expect(response.statusCode).toBe(400);
            expect(response.body.errors.login).toHaveProperty("msg", "Invalid email or password");
    });

    it("log in user | missing email and password (err)", async () => {
        const response = await request(app)
            .post("/api/auth/login")
            .send({
                // email: "wrongemail@example.com",
                // password: "wrongpassword",
            });

            expect(response.statusCode).toBe(400);
            expect(response.body.errors.login).toHaveProperty("msg", "Invalid email or password");
    });
})